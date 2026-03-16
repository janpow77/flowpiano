using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Input;
using FlowPiano.Windows.Core;
using FlowPiano.Windows.Platform;

namespace FlowPiano.Windows.App;

public sealed class MainWindowViewModel : INotifyPropertyChanged, IDisposable
{
    private readonly FlowPianoSessionCoordinator _coordinator;
    private readonly FlowPianoWindowsRuntimeHost _runtimeHost;

    public MainWindowViewModel()
    {
        _coordinator = new FlowPianoSessionCoordinator(
            new FileSettingsStore(Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "FlowPiano",
                "WindowsSettings"))
        );
        InstallPreviewVideoProfile();

        _runtimeHost = new FlowPianoWindowsRuntimeHost(_coordinator, SoundBankPath());
        _runtimeHost.StateChanged += OnRuntimeStateChanged;
        _runtimeHost.Start();

        _coordinator.StartSession();
        _runtimeHost.SyncAudioConfiguration();
        _runtimeHost.SyncVideoConfiguration();

        PlayPhraseCommand = new RelayCommand(PlayPhrase);
        RefreshHardwareCommand = new RelayCommand(() =>
        {
            _runtimeHost.RefreshHardware();
            Refresh();
        });
        SwapCamerasCommand = new RelayCommand(() =>
        {
            _coordinator.SwapCameraRoles();
            _runtimeHost.SyncVideoConfiguration();
            Refresh();
        });
        ToggleInternalPianoCommand = new RelayCommand(() =>
        {
            _coordinator.SetInternalPianoEnabled(!_coordinator.Snapshot.Audio.InternalPianoEnabled);
            _runtimeHost.SyncAudioConfiguration();
            Refresh();
        });
        CycleRoutingCommand = new RelayCommand(() =>
        {
            var nextMode = _coordinator.Snapshot.Audio.RoutingMode switch
            {
                AudioRoutingMode.InternalOnly => AudioRoutingMode.Layered,
                AudioRoutingMode.Layered => AudioRoutingMode.ExternalOnly,
                _ => AudioRoutingMode.InternalOnly
            };

            _coordinator.SetRoutingMode(nextMode);
            _coordinator.SetExternalInstrumentConnected(nextMode != AudioRoutingMode.InternalOnly);
            _coordinator.SetSpeechInputLevel(nextMode == AudioRoutingMode.ExternalOnly ? 0.15 : 0.35);
            _runtimeHost.SyncAudioConfiguration();
            Refresh();
        });
        ToggleVirtualDevicesCommand = new RelayCommand(() =>
        {
            _runtimeHost.RefreshHardware();
            Refresh();
        });
        SaveSettingsCommand = new RelayCommand(() =>
        {
            _coordinator.SaveSettings();
            Refresh();
        });

        Refresh();
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    public FlowPianoRuntimeSnapshot Snapshot => _coordinator.Snapshot;
    public string ReadinessText => Snapshot.Diagnostics.IsReleaseReady ? "Release Gate Clear" : "Release Gate Blocked";
    public string MainCameraName => Snapshot.Video.MainCamera?.Name ?? "None";
    public string PipCameraName => Snapshot.Video.PipCamera?.Name ?? "None";
    public string MidiDeviceName => Snapshot.Midi.ConnectedDevice?.Name ?? "Disconnected";
    public string RoutingMode => Snapshot.Audio.RoutingMode.ToString();
    public string PianoBankName => Snapshot.Audio.Runtime.PianoSoundBankName;
    public string RuntimeMode => _runtimeHost.RuntimeDescription;
    public string PlatformError => _runtimeHost.LastError ?? Snapshot.Video.Runtime.LastError ?? Snapshot.Audio.Runtime.LastError ?? "No platform error";
    public string RuntimeDirectory => _runtimeHost.RuntimeDirectory;
    public string CaptureSessionManifestPath => _runtimeHost.CaptureSessionManifestPath;
    public string VirtualCameraState => Snapshot.VirtualCamera.IsInstalled ? "Registered" : "Bridge only";
    public string VirtualAudioState => Snapshot.VirtualAudio.IsInstalled ? "Registered" : "Bridge only";
    public string VirtualCameraPath => _runtimeHost.VirtualCameraFeedPath;
    public string VirtualAudioPath => _runtimeHost.VirtualAudioFeedPath;
    public string VirtualCameraBridgePath => _runtimeHost.VirtualCameraBridgePath;
    public string VirtualCameraManifestPath => _runtimeHost.VirtualCameraManifestPath;
    public string VirtualAudioBridgePath => _runtimeHost.VirtualAudioBridgePath;
    public string VirtualAudioManifestPath => _runtimeHost.VirtualAudioManifestPath;

    public IReadOnlyList<SetupChecklistItem> SetupChecklist => Snapshot.SetupChecklist;
    public IReadOnlyList<DiagnosticIssue> DiagnosticIssues => Snapshot.Diagnostics.Issues;
    public IReadOnlyList<RenderedLayer> PublicLayers => Snapshot.PublicScene.Layers;
    public IReadOnlyList<LayerKind> StudioLayers => Snapshot.StudioMonitor.VisibleLayers;

    public ICommand PlayPhraseCommand { get; }
    public ICommand RefreshHardwareCommand { get; }
    public ICommand SwapCamerasCommand { get; }
    public ICommand ToggleInternalPianoCommand { get; }
    public ICommand CycleRoutingCommand { get; }
    public ICommand ToggleVirtualDevicesCommand { get; }
    public ICommand SaveSettingsCommand { get; }

    public void Dispose()
    {
        _runtimeHost.StateChanged -= OnRuntimeStateChanged;
        _runtimeHost.Dispose();
        GC.SuppressFinalize(this);
    }

    private void PlayPhrase()
    {
        if (!Snapshot.Midi.IsConnected)
        {
            _runtimeHost.RefreshHardware();
        }

        if (!Snapshot.Midi.IsConnected)
        {
            Refresh();
            return;
        }

        var sourceDeviceId = Snapshot.Midi.ConnectedDeviceId;
        foreach (var note in new[] { 60, 64, 67 })
        {
            _runtimeHost.DispatchMidiEvent(new MidiEvent(note, 96, true, SourceDeviceId: sourceDeviceId));
        }

        foreach (var note in new[] { 67, 64, 60 })
        {
            _runtimeHost.DispatchMidiEvent(new MidiEvent(note, 0, false, SourceDeviceId: sourceDeviceId));
        }

        Refresh();
    }

    private void Refresh()
    {
        OnPropertyChanged(nameof(Snapshot));
        OnPropertyChanged(nameof(ReadinessText));
        OnPropertyChanged(nameof(MainCameraName));
        OnPropertyChanged(nameof(PipCameraName));
        OnPropertyChanged(nameof(MidiDeviceName));
        OnPropertyChanged(nameof(RoutingMode));
        OnPropertyChanged(nameof(PianoBankName));
        OnPropertyChanged(nameof(RuntimeMode));
        OnPropertyChanged(nameof(PlatformError));
        OnPropertyChanged(nameof(RuntimeDirectory));
        OnPropertyChanged(nameof(CaptureSessionManifestPath));
        OnPropertyChanged(nameof(VirtualCameraState));
        OnPropertyChanged(nameof(VirtualAudioState));
        OnPropertyChanged(nameof(VirtualCameraPath));
        OnPropertyChanged(nameof(VirtualAudioPath));
        OnPropertyChanged(nameof(VirtualCameraBridgePath));
        OnPropertyChanged(nameof(VirtualCameraManifestPath));
        OnPropertyChanged(nameof(VirtualAudioBridgePath));
        OnPropertyChanged(nameof(VirtualAudioManifestPath));
        OnPropertyChanged(nameof(SetupChecklist));
        OnPropertyChanged(nameof(DiagnosticIssues));
        OnPropertyChanged(nameof(PublicLayers));
        OnPropertyChanged(nameof(StudioLayers));
    }

    private void InstallPreviewVideoProfile()
    {
        _coordinator.UpdateAvailableCameras(
            [
                new CameraDevice("preview-main", "Preview Main Camera", CameraPosition.Front),
                new CameraDevice("preview-pip", "Preview Keyboard Camera", CameraPosition.External)
            ],
            new VideoCapabilities(true, 2)
        );
    }

    private void OnRuntimeStateChanged(object? sender, EventArgs eventArgs)
    {
        var dispatcher = Application.Current?.Dispatcher;
        if (dispatcher is null || dispatcher.CheckAccess())
        {
            Refresh();
            return;
        }

        dispatcher.BeginInvoke(new Action(Refresh));
    }

    private static string SoundBankPath() => Path.Combine(AppContext.BaseDirectory, "Resources", "GeneralUser GS v1.471.sf2");

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}
