using FlowPiano.Windows.Core;

namespace FlowPiano.Windows.Platform;

public sealed class FlowPianoWindowsRuntimeHost : IDisposable
{
    private readonly object _gate = new();
    private readonly FlowPianoSessionCoordinator _coordinator;
    private readonly IWindowsVideoCaptureService _videoCapture;
    private readonly IWindowsMidiInputService _midiInput;
    private readonly IWindowsAudioRuntimeService _audioRuntime;
    private readonly WindowsPreviewArtifactWriter _artifactWriter;
    private readonly WindowsCaptureSessionWriter _captureSessionWriter;
    private readonly IWindowsVirtualCameraPublisher _virtualCameraPublisher;
    private readonly IWindowsVirtualMicrophonePublisher _virtualMicrophonePublisher;

    private bool _usingPreviewVideoFallback = true;
    private string? _videoError;
    private string? _midiError;
    private string? _audioError;
    private string? _artifactError;
    private string? _captureSessionError;
    private string? _virtualCameraError;
    private string? _virtualAudioError;

    public FlowPianoWindowsRuntimeHost(
        FlowPianoSessionCoordinator coordinator,
        string? bundledSoundBankPath = null,
        IWindowsVideoCaptureService? videoCapture = null,
        IWindowsMidiInputService? midiInput = null,
        IWindowsAudioRuntimeService? audioRuntime = null,
        WindowsPreviewArtifactWriter? artifactWriter = null,
        WindowsCaptureSessionWriter? captureSessionWriter = null,
        IWindowsVirtualCameraPublisher? virtualCameraPublisher = null,
        IWindowsVirtualMicrophonePublisher? virtualMicrophonePublisher = null)
    {
        _coordinator = coordinator;
        _videoCapture = videoCapture ?? new CompositeVideoCaptureService(new MediaFoundationVideoCaptureService(), new WmiVideoCaptureService());
        _midiInput = midiInput ?? new WinMmMidiInputService();
        _audioRuntime = audioRuntime ?? new WinMmAudioRuntimeService(bundledSoundBankPath);
        _artifactWriter = artifactWriter ?? new WindowsPreviewArtifactWriter(DefaultRuntimeDirectory());
        _captureSessionWriter = captureSessionWriter ?? new WindowsCaptureSessionWriter(_artifactWriter.RuntimeDirectory);
        _virtualCameraPublisher = virtualCameraPublisher ?? new MediaFoundationVirtualCameraPublisher(_artifactWriter.RuntimeDirectory);
        _virtualMicrophonePublisher = virtualMicrophonePublisher ?? new VirtualAudioDriverPublisher(_artifactWriter.RuntimeDirectory);
        _midiInput.MidiEventReceived += OnMidiEventReceived;
    }

    public event EventHandler? StateChanged;

    public string RuntimeDescription { get; private set; } = "Windows runtime bridge not started.";

    public string? LastError { get; private set; }

    public string RuntimeDirectory => _artifactWriter.RuntimeDirectory;
    public string CaptureSessionManifestPath => _captureSessionWriter.ManifestPath;
    public string VirtualCameraFeedPath => _virtualCameraPublisher.PublicationPath;
    public string VirtualCameraBridgePath => _virtualCameraPublisher.BridgePath;
    public string VirtualCameraManifestPath => _virtualCameraPublisher.ManifestPath;
    public string VirtualAudioFeedPath => _virtualMicrophonePublisher.PublicationPath;
    public string VirtualAudioBridgePath => _virtualMicrophonePublisher.BridgePath;
    public string VirtualAudioManifestPath => _virtualMicrophonePublisher.ManifestPath;

    public void Start()
    {
        lock (_gate)
        {
            RefreshHardwareCore();
        }

        StateChanged?.Invoke(this, EventArgs.Empty);
    }

    public void RefreshHardware()
    {
        lock (_gate)
        {
            RefreshHardwareCore();
        }

        StateChanged?.Invoke(this, EventArgs.Empty);
    }

    public void SyncAudioConfiguration()
    {
        lock (_gate)
        {
            SyncAudioConfigurationCore();
            UpdateRuntimeDescription();
            PublishArtifactsCore();
        }

        StateChanged?.Invoke(this, EventArgs.Empty);
    }

    public void SyncVideoConfiguration()
    {
        lock (_gate)
        {
            SyncVideoConfigurationCore();
            UpdateRuntimeDescription();
            PublishArtifactsCore();
        }

        StateChanged?.Invoke(this, EventArgs.Empty);
    }

    public void DispatchMidiEvent(MidiEvent midiEvent)
    {
        lock (_gate)
        {
            try
            {
                _audioRuntime.HandleMidiEvent(midiEvent);
                _coordinator.ReceiveMidiEvent(midiEvent);
                _midiError = null;
            }
            catch (Exception exception)
            {
                _midiError = exception.Message;
            }

            UpdateRuntimeDescription();
            PublishArtifactsCore();
        }

        StateChanged?.Invoke(this, EventArgs.Empty);
    }

    public void Dispose()
    {
        _midiInput.MidiEventReceived -= OnMidiEventReceived;
        _videoCapture.StopCapture();
        _midiInput.Disconnect();
        _audioRuntime.Stop();
        (_videoCapture as IDisposable)?.Dispose();
        (_midiInput as IDisposable)?.Dispose();
        (_audioRuntime as IDisposable)?.Dispose();
        (_virtualCameraPublisher as IDisposable)?.Dispose();
        (_virtualMicrophonePublisher as IDisposable)?.Dispose();
        GC.SuppressFinalize(this);
    }

    private void OnMidiEventReceived(object? sender, MidiEvent midiEvent) => DispatchMidiEvent(midiEvent);

    private void RefreshHardwareCore()
    {
        RefreshVideoCore();
        RefreshMidiCore();
        SyncAudioConfigurationCore();
        RefreshVirtualDevicesCore();
        UpdateRuntimeDescription();
        PublishArtifactsCore();
    }

    private void RefreshVideoCore()
    {
        try
        {
            var cameras = _videoCapture.EnumerateCameras();
            if (cameras.Count == 0)
            {
                _usingPreviewVideoFallback = true;
                _videoError = null;
                _coordinator.SetVideoRuntime(new VideoRuntimeState(false, true, false, "No live Windows cameras were detected. Preview camera profile remains active."));
                RefreshLastError();
                return;
            }

            _coordinator.UpdateAvailableCameras(cameras, _videoCapture.QueryCapabilities());
            _usingPreviewVideoFallback = false;
            SyncVideoConfigurationCore();
        }
        catch (Exception exception)
        {
            _usingPreviewVideoFallback = true;
            _videoError = exception.Message;
            _coordinator.SetVideoRuntime(new VideoRuntimeState(false, true, false, exception.Message));
            RefreshLastError();
        }
    }

    private void RefreshMidiCore()
    {
        IReadOnlyList<MidiDevice> devices;
        try
        {
            devices = _midiInput.EnumerateDevices();
            _coordinator.UpdateAvailableMidiInputs(devices);
        }
        catch (Exception exception)
        {
            _midiError = exception.Message;
            devices = Array.Empty<MidiDevice>();
            _coordinator.UpdateAvailableMidiInputs(devices);
            RefreshLastError();
            return;
        }

        var connectedDeviceId = ResolveMidiDeviceId(devices);
        try
        {
            _midiInput.Connect(connectedDeviceId);
            _coordinator.ConnectMidiInput(connectedDeviceId);
            _midiError = null;
        }
        catch (Exception exception)
        {
            _midiError = exception.Message;
            _midiInput.Disconnect();
            _coordinator.ConnectMidiInput(null);
        }

        RefreshLastError();
    }

    private void SyncVideoConfigurationCore()
    {
        if (_usingPreviewVideoFallback)
        {
            _videoError = null;
            _coordinator.SetVideoRuntime(new VideoRuntimeState(false, true, false, "Preview camera profile remains active until Windows live capture is available."));
            RefreshVirtualDevicesCore();
            RefreshLastError();
            return;
        }

        try
        {
            _videoCapture.StartCapture(_coordinator.Snapshot.Video.Assignment);
            var runtime = _videoCapture.QueryRuntimeState();
            _coordinator.SetVideoRuntime(runtime);
            _videoError = runtime.LastError;
        }
        catch (Exception exception)
        {
            _videoError = exception.Message;
            _coordinator.SetVideoRuntime(new VideoRuntimeState(false, false, false, exception.Message));
        }

        RefreshVirtualDevicesCore();
        RefreshLastError();
    }

    private void SyncAudioConfigurationCore()
    {
        _audioRuntime.SetRouting(_coordinator.Snapshot.Audio.RoutingMode, _coordinator.Snapshot.Audio.InternalPianoEnabled);
        _audioRuntime.Start(_coordinator.Snapshot.Audio.MixProfile);
        _audioRuntime.SetRouting(_coordinator.Snapshot.Audio.RoutingMode, _coordinator.Snapshot.Audio.InternalPianoEnabled);

        var runtime = _audioRuntime.QueryRuntimeState();
        _coordinator.SetAudioRuntime(runtime);
        _audioError = runtime.LastError;

        var cameraGranted = _coordinator.Snapshot.Video.Runtime.PlatformVideoAvailable;
        _coordinator.SetPermissions(
            cameraGranted: cameraGranted,
            microphoneGranted: runtime.SpeechInputAvailable,
            audioOutputGranted: runtime.PlatformAudioAvailable);

        RefreshVirtualDevicesCore();
        RefreshLastError();
    }

    private void PublishArtifactsCore()
    {
        RefreshLastError();

        try
        {
            _artifactWriter.Publish(_coordinator.Snapshot, RuntimeDescription, LastError, _usingPreviewVideoFallback);
            _artifactError = null;
        }
        catch (Exception exception)
        {
            _artifactError = exception.Message;
        }

        try
        {
            _captureSessionWriter.Publish(_coordinator.Snapshot, RuntimeDescription, LastError, _usingPreviewVideoFallback);
            _captureSessionError = null;
        }
        catch (Exception exception)
        {
            _captureSessionError = exception.Message;
        }

        PublishVirtualDevicesCore();
        RefreshLastError();
    }

    private void UpdateRuntimeDescription()
    {
        var midiName = _coordinator.Snapshot.Midi.ConnectedDevice?.Name ?? "no MIDI keyboard";
        var audioName = _coordinator.Snapshot.Audio.Runtime.PianoSoundBankName;
        var synthMode = _coordinator.Snapshot.Audio.Runtime.PianoSoundBankSource == PianoSoundBankSource.Unavailable
            ? "Windows synth unavailable"
            : $"Windows synth: {audioName}";
        var videoMode = _usingPreviewVideoFallback
            ? $"Video preview fallback: {_coordinator.Snapshot.Video.MainCamera?.Name ?? "Preview Main Camera"}"
            : _coordinator.Snapshot.Video.Runtime.CaptureConfigured
                ? $"Live video: {_coordinator.Snapshot.Video.MainCamera?.Name ?? "Main Camera"}"
                : "Live video discovery only";

        RuntimeDescription = $"Live MIDI via WinMM: {midiName} | {synthMode} | {videoMode}";
    }

    private void RefreshLastError()
    {
        LastError = _videoError ?? _midiError ?? _audioError ?? _virtualCameraError ?? _virtualAudioError ?? _artifactError ?? _captureSessionError;
    }

    private string? ResolveMidiDeviceId(IReadOnlyList<MidiDevice> devices)
    {
        if (devices.Count == 0)
        {
            return null;
        }

        var preferredId = _coordinator.Snapshot.Settings.Midi.PreferredInputDeviceId;
        if (preferredId is not null && devices.Any(device => device.Id == preferredId && device.IsAvailable))
        {
            return preferredId;
        }

        return devices.FirstOrDefault(device => device.IsAvailable)?.Id;
    }

    private static string DefaultRuntimeDirectory() =>
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "FlowPiano", "Runtime");

    private void RefreshVirtualDevicesCore()
    {
        try
        {
            _virtualCameraPublisher.Refresh();
            _virtualCameraError = _virtualCameraPublisher.LastError;
            _coordinator.SetVirtualCameraStatus(
                _virtualCameraPublisher.IsInstalled,
                _virtualCameraPublisher.IsPublishing,
                _coordinator.Snapshot.PublicScene.Layers.Select(layer => layer.Kind).ToArray(),
                _virtualCameraPublisher.PublicationPath,
                _virtualCameraPublisher.LastError);
        }
        catch (Exception exception)
        {
            _virtualCameraError = exception.Message;
            _coordinator.SetVirtualCameraStatus(
                false,
                false,
                publicationPath: WindowsRuntimeArtifacts.PathFor(_artifactWriter.RuntimeDirectory, WindowsRuntimeArtifacts.PublicOutputSceneFileName),
                lastError: exception.Message);
        }

        try
        {
            _virtualMicrophonePublisher.Refresh();
            _virtualAudioError = _virtualMicrophonePublisher.LastError;
            _coordinator.SetVirtualAudioStatus(
                _virtualMicrophonePublisher.IsInstalled,
                _virtualMicrophonePublisher.IsPublishing,
                _coordinator.Snapshot.Audio.Meters.MasterLevel,
                _virtualMicrophonePublisher.PublicationPath,
                _virtualMicrophonePublisher.LastError);
        }
        catch (Exception exception)
        {
            _virtualAudioError = exception.Message;
            _coordinator.SetVirtualAudioStatus(
                false,
                false,
                publicationPath: WindowsRuntimeArtifacts.PathFor(_artifactWriter.RuntimeDirectory, WindowsRuntimeArtifacts.VirtualMicrophoneFeedFileName),
                lastError: exception.Message);
        }

        RefreshLastError();
    }

    private void PublishVirtualDevicesCore()
    {
        try
        {
            _virtualCameraPublisher.Publish(_coordinator.Snapshot.PublicScene);
            _virtualCameraError = _virtualCameraPublisher.LastError;
            _coordinator.SetVirtualCameraStatus(
                _virtualCameraPublisher.IsInstalled,
                _virtualCameraPublisher.IsPublishing,
                _coordinator.Snapshot.PublicScene.Layers.Select(layer => layer.Kind).ToArray(),
                _virtualCameraPublisher.PublicationPath,
                _virtualCameraPublisher.LastError);
        }
        catch (Exception exception)
        {
            _virtualCameraError = exception.Message;
            _coordinator.SetVirtualCameraStatus(
                _virtualCameraPublisher.IsInstalled,
                false,
                publicationPath: _virtualCameraPublisher.PublicationPath,
                lastError: exception.Message);
        }

        try
        {
            _virtualMicrophonePublisher.Publish(new VirtualMicrophoneFeed(_coordinator.Snapshot.Audio.ActiveNotes, _coordinator.Snapshot.Audio.Meters));
            _virtualAudioError = _virtualMicrophonePublisher.LastError;
            _coordinator.SetVirtualAudioStatus(
                _virtualMicrophonePublisher.IsInstalled,
                _virtualMicrophonePublisher.IsPublishing,
                _coordinator.Snapshot.Audio.Meters.MasterLevel,
                _virtualMicrophonePublisher.PublicationPath,
                _virtualMicrophonePublisher.LastError);
        }
        catch (Exception exception)
        {
            _virtualAudioError = exception.Message;
            _coordinator.SetVirtualAudioStatus(
                _virtualMicrophonePublisher.IsInstalled,
                false,
                _coordinator.Snapshot.Audio.Meters.MasterLevel,
                _virtualMicrophonePublisher.PublicationPath,
                exception.Message);
        }

        RefreshLastError();
    }
}
