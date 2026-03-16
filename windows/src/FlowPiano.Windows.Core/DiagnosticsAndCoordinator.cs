using System.Text.Json;

namespace FlowPiano.Windows.Core;

public enum SetupStep
{
    Permissions,
    MainCamera,
    PipCamera,
    MidiKeyboard,
    InternalPiano,
    OverlayPlacement,
    StudioNotation,
    VirtualDevices
}

public sealed record SetupChecklistItem(SetupStep Step, bool IsComplete, string Detail);

public sealed record PermissionState(bool CameraGranted = false, bool MicrophoneGranted = false, bool AudioOutputGranted = false);

public enum DiagnosticSeverity
{
    Info,
    Warning,
    Critical
}

public enum DiagnosticCode
{
    MissingCameraPermission,
    MissingMicrophonePermission,
    NoCameraAvailable,
    MultiCamFallback,
    NoMidiDevice,
    InternalPianoDisabled,
    MissingPianoSoundBank,
    PublicSceneViolation,
    VirtualCameraUnavailable,
    VirtualAudioUnavailable,
    SetupIncomplete
}

public sealed record DiagnosticIssue(DiagnosticCode Code, DiagnosticSeverity Severity, string Message, string RecoverySuggestion);

public sealed record DiagnosticsReport(IReadOnlyList<DiagnosticIssue> Issues, bool IsReleaseReady);

public sealed record VirtualCameraStatus
{
    public VirtualCameraStatus(
        bool isInstalled = false,
        bool isPublishing = false,
        IReadOnlyList<LayerKind>? lastPublishedLayerKinds = null,
        string? publicationPath = null,
        string? lastError = null
    )
    {
        IsInstalled = isInstalled;
        IsPublishing = isPublishing;
        LastPublishedLayerKinds = lastPublishedLayerKinds ?? Array.Empty<LayerKind>();
        PublicationPath = publicationPath;
        LastError = lastError;
    }

    public bool IsInstalled { get; init; }
    public bool IsPublishing { get; init; }
    public IReadOnlyList<LayerKind> LastPublishedLayerKinds { get; init; }
    public string? PublicationPath { get; init; }
    public string? LastError { get; init; }
}

public sealed record VirtualAudioDriverStatus(bool IsInstalled = false, bool IsPublishing = false, double LastMasterLevel = 0, string? PublicationPath = null, string? LastError = null);

public sealed record VirtualMicrophoneFeed(IReadOnlyList<int> ActiveNotes, AudioMeterState Meters);

public sealed record StudioMonitorState(bool NotationEnabled = true, bool DiagnosticsEnabled = true, bool MetersEnabled = true, bool EventLogEnabled = true, bool LatencyIndicatorEnabled = true);

public sealed record StudioMonitorSnapshot(
    IReadOnlyList<LayerKind> VisibleLayers,
    NotationState? Notation,
    AudioMeterState? AudioMeters,
    IReadOnlyList<MidiEventLogEntry> MidiLog,
    DiagnosticsReport? Diagnostics,
    double? LatencyMilliseconds
);

public sealed record FlowPianoRuntimeSnapshot(
    AppSettings Settings,
    PermissionState Permissions,
    VideoSessionState Video,
    MidiConnectionStatus Midi,
    AudioEngineState Audio,
    NotationState Notation,
    MidiOverlayState Overlay,
    DiagnosticsReport Diagnostics,
    RenderScene PublicScene,
    StudioMonitorSnapshot StudioMonitor,
    VirtualCameraStatus VirtualCamera,
    VirtualAudioDriverStatus VirtualAudio,
    IReadOnlyList<SetupChecklistItem> SetupChecklist,
    IReadOnlyList<LayerKind> PublicSceneViolations,
    double EstimatedLatencyMilliseconds
);

public static class DiagnosticsEngine
{
    public static DiagnosticsReport BuildReport(
        PermissionState permissions,
        VideoSessionState video,
        MidiConnectionStatus midi,
        AudioEngineState audio,
        IReadOnlyList<LayerKind> publicSceneViolations,
        VirtualCameraStatus virtualCamera,
        VirtualAudioDriverStatus virtualAudio,
        bool setupComplete
    )
    {
        var issues = new List<DiagnosticIssue>();

        if (!permissions.CameraGranted)
        {
            issues.Add(new DiagnosticIssue(DiagnosticCode.MissingCameraPermission, DiagnosticSeverity.Critical, "Camera permission has not been granted.", "Grant camera access before starting a lesson."));
        }

        if (!permissions.MicrophoneGranted)
        {
            issues.Add(new DiagnosticIssue(DiagnosticCode.MissingMicrophonePermission, DiagnosticSeverity.Critical, "Microphone permission has not been granted.", "Grant microphone access so speech mixing can work."));
        }

        if (video.Warnings.Contains(VideoWarning.NoCameraAvailable))
        {
            issues.Add(new DiagnosticIssue(DiagnosticCode.NoCameraAvailable, DiagnosticSeverity.Critical, "No camera is currently available.", "Connect at least one supported camera."));
        }

        if (video.Warnings.Contains(VideoWarning.MultiCamUnavailable))
        {
            issues.Add(new DiagnosticIssue(DiagnosticCode.MultiCamFallback, DiagnosticSeverity.Warning, "Multi-camera capture is unavailable.", "Use a supported hardware combination or stay in single-camera mode."));
        }

        if (!midi.IsConnected)
        {
            issues.Add(new DiagnosticIssue(DiagnosticCode.NoMidiDevice, DiagnosticSeverity.Warning, "No MIDI keyboard is connected.", "Reconnect the keyboard or choose another MIDI input."));
        }

        if (!audio.InternalPianoEnabled && audio.RoutingMode == AudioRoutingMode.InternalOnly)
        {
            issues.Add(new DiagnosticIssue(DiagnosticCode.InternalPianoDisabled, DiagnosticSeverity.Warning, "Internal piano mode is disabled while routing is internal only.", "Enable the internal piano or switch routing mode."));
        }

        if (audio.InternalPianoEnabled && audio.Runtime.PianoSoundBankSource == PianoSoundBankSource.Unavailable)
        {
            issues.Add(new DiagnosticIssue(DiagnosticCode.MissingPianoSoundBank, DiagnosticSeverity.Critical, "No piano sound bank is available.", "Bundle a compatible SF2/DLS bank or configure a system piano bank."));
        }

        if (publicSceneViolations.Count > 0)
        {
            issues.Add(new DiagnosticIssue(DiagnosticCode.PublicSceneViolation, DiagnosticSeverity.Critical, $"Public Output contains studio-only layers: {string.Join(", ", publicSceneViolations)}.", "Remove notation, meters, logs, latency indicators, and diagnostics from Target A."));
        }

        if (!virtualCamera.IsInstalled)
        {
            issues.Add(new DiagnosticIssue(DiagnosticCode.VirtualCameraUnavailable, DiagnosticSeverity.Info, "Virtual camera is not installed.", "Install and register the Windows virtual camera component."));
        }

        if (!virtualAudio.IsInstalled)
        {
            issues.Add(new DiagnosticIssue(DiagnosticCode.VirtualAudioUnavailable, DiagnosticSeverity.Info, "Virtual microphone is not installed.", "Install and register the Windows virtual audio driver."));
        }

        if (!setupComplete)
        {
            issues.Add(new DiagnosticIssue(DiagnosticCode.SetupIncomplete, DiagnosticSeverity.Info, "The setup flow is incomplete.", "Work through permissions, device selection, overlay placement, and virtual device validation."));
        }

        var hasCriticalIssue = issues.Any(issue => issue.Severity == DiagnosticSeverity.Critical);
        return new DiagnosticsReport(issues, !hasCriticalIssue && setupComplete && publicSceneViolations.Count == 0);
    }
}

public sealed class FlowPianoSessionCoordinator
{
    private readonly ISettingsStore _settingsStore;
    private const string SettingsKey = "flowpiano-windows-settings";

    private readonly VideoEngine _videoEngine;
    private readonly MidiEngine _midiEngine;
    private readonly AudioEngine _audioEngine;
    private readonly NotationEngine _notationEngine;
    private readonly OverlayEngine _overlayEngine;

    private AppSettings _settings;
    private PermissionState _permissions = new();
    private StudioMonitorState _studioMonitorState = new();
    private VirtualCameraStatus _virtualCamera = new(publicationPath: PublicationPath("public-output-scene.json"));
    private VirtualAudioDriverStatus _virtualAudio = new(PublicationPath: PublicationPath("virtual-microphone-feed.json"));

    public FlowPianoRuntimeSnapshot Snapshot { get; private set; }

    public FlowPianoSessionCoordinator(ISettingsStore? settingsStore = null)
    {
        _settingsStore = settingsStore ?? new InMemorySettingsStore();
        _videoEngine = new VideoEngine();
        _midiEngine = new MidiEngine();
        _audioEngine = new AudioEngine();
        _notationEngine = new NotationEngine();
        _overlayEngine = new OverlayEngine();
        _settings = _settingsStore.Load<AppSettings>(SettingsKey) ?? AppSettings.Default;

        ApplySettingsToEngines();
        Snapshot = new FlowPianoRuntimeSnapshot(
            _settings,
            _permissions,
            _videoEngine.State,
            _midiEngine.State,
            _audioEngine.State,
            _notationEngine.State,
            _overlayEngine.State,
            new DiagnosticsReport([], false),
            LayoutEngine.BuildScene(LayoutEngine.SanitizedForPublicOutput(_settings.Layout), RenderTarget.PublicOutput),
            new StudioMonitorSnapshot([], null, null, [], null, null),
            _virtualCamera,
            _virtualAudio,
            [],
            [],
            0
        );

        RefreshSnapshot();
    }

    public void InstallPreviewHardwareProfile()
    {
        UpdateAvailableCameras(
            [
                new CameraDevice("cam-face", "Face Camera", CameraPosition.Front),
                new CameraDevice("cam-keys", "Keyboard Camera", CameraPosition.External)
            ],
            new VideoCapabilities(true, 2)
        );
        UpdateAvailableMidiInputs([new MidiDevice("midi-main", "88-Key Controller")]);
        ConnectMidiInput("midi-main");
        SetPermissions(true, true, true);
        SetVirtualDevicesInstalled(true, true);
    }

    public void StartSession()
    {
        _audioEngine.Start();
        try
        {
            _videoEngine.Start();
        }
        catch
        {
        }
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void SetPermissions(bool cameraGranted, bool microphoneGranted, bool audioOutputGranted)
    {
        _permissions = new PermissionState(cameraGranted, microphoneGranted, audioOutputGranted);
        RefreshSnapshot();
    }

    public void UpdateAvailableCameras(IEnumerable<CameraDevice> devices, VideoCapabilities capabilities)
    {
        _videoEngine.UpdateDevices(devices, capabilities);
        if (_settings.Video.PreferredMainCameraId is not null)
        {
            _videoEngine.SelectCamera(_settings.Video.PreferredMainCameraId, CameraRole.Main);
        }
        if (_settings.Video.PreferredPipCameraId is not null)
        {
            _videoEngine.SelectCamera(_settings.Video.PreferredPipCameraId, CameraRole.Pip);
        }

        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void SetVideoRuntime(VideoRuntimeState runtime)
    {
        _videoEngine.SetRuntime(runtime);
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void SelectCamera(string? id, CameraRole role)
    {
        _videoEngine.SelectCamera(id, role);
        _settings = _settings with
        {
            Video = role switch
            {
                CameraRole.Main => _settings.Video with { PreferredMainCameraId = _videoEngine.State.Assignment.MainCameraId },
                CameraRole.Pip => _settings.Video with { PreferredPipCameraId = _videoEngine.State.Assignment.PipCameraId },
                _ => _settings.Video
            }
        };

        PersistSettings();
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void SwapCameraRoles()
    {
        _videoEngine.SwapCameraRoles();
        _settings = _settings with
        {
            Video = _settings.Video with
            {
                PreferredMainCameraId = _videoEngine.State.Assignment.MainCameraId,
                PreferredPipCameraId = _videoEngine.State.Assignment.PipCameraId
            },
            Layout = LayoutEngine.SwapCameraFrames(_settings.Layout)
        };

        PersistSettings();
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void UpdateAvailableMidiInputs(IEnumerable<MidiDevice> devices)
    {
        _midiEngine.UpdateAvailableDevices(devices);
        if (_settings.Midi.AutoReconnect && _settings.Midi.PreferredInputDeviceId is not null)
        {
            try
            {
                _midiEngine.Connect(_settings.Midi.PreferredInputDeviceId);
            }
            catch
            {
            }
        }
        RefreshSnapshot();
    }

    public void ConnectMidiInput(string? id)
    {
        _midiEngine.Connect(id);
        _settings = _settings with { Midi = _settings.Midi with { PreferredInputDeviceId = _midiEngine.State.ConnectedDeviceId } };
        PersistSettings();
        RefreshSnapshot();
    }

    public void ReceiveMidiEvent(MidiEvent midiEvent)
    {
        _midiEngine.Receive(midiEvent);
        _audioEngine.Process(midiEvent);
        _notationEngine.Consume(midiEvent);
        _overlayEngine.Update(_midiEngine.State);
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void SetInternalPianoEnabled(bool enabled)
    {
        _settings = _settings with { Audio = _settings.Audio with { UseInternalPiano = enabled } };
        _audioEngine.SetInternalPianoEnabled(enabled);
        PersistSettings();
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void SetRoutingMode(AudioRoutingMode mode)
    {
        _settings = _settings with { Audio = _settings.Audio with { RoutingPreference = ToPreference(mode) } };
        _audioEngine.SetRoutingMode(mode);
        PersistSettings();
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void SetSpeechInputLevel(double level)
    {
        _audioEngine.SetSpeechInputLevel(level);
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void SetAudioRuntime(AudioRuntimeState runtime)
    {
        _audioEngine.SetRuntime(runtime);
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void SetExternalInstrumentConnected(bool connected)
    {
        _audioEngine.SetExternalInstrumentConnected(connected);
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void MoveOverlay(double x, double y)
    {
        _settings = _settings with { Layout = LayoutEngine.MoveLayer(_settings.Layout, LayerKind.MidiOverlay, x, y) };
        SyncOverlayFrameFromLayout();
        PersistSettings();
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void ResizeOverlay(double width, double height)
    {
        _settings = _settings with { Layout = LayoutEngine.ResizeLayer(_settings.Layout, LayerKind.MidiOverlay, width, height) };
        SyncOverlayFrameFromLayout();
        PersistSettings();
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void SetOverlayVisible(bool isVisible)
    {
        _settings = _settings with { Overlay = _settings.Overlay with { IsVisible = isVisible } };
        _overlayEngine.SetVisible(isVisible);
        PersistSettings();
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void SetOverlayLabelsVisible(bool showLabels)
    {
        _settings = _settings with { Overlay = _settings.Overlay with { ShowLabels = showLabels } };
        _overlayEngine.SetShowLabels(showLabels);
        PersistSettings();
        RefreshSnapshot();
    }

    public void SetStudioMonitorState(StudioMonitorState state)
    {
        _studioMonitorState = state;
        _settings = _settings with
        {
            StudioMonitor = new StudioMonitorSettings(state.NotationEnabled, state.DiagnosticsEnabled, state.MetersEnabled, state.EventLogEnabled, state.LatencyIndicatorEnabled)
        };
        PersistSettings();
        RefreshSnapshot();
    }

    public void SetVirtualDevicesInstalled(bool cameraInstalled, bool audioInstalled)
    {
        _virtualCamera = _virtualCamera with { IsInstalled = cameraInstalled, PublicationPath = PublicationPath("public-output-scene.json") };
        _virtualAudio = _virtualAudio with { IsInstalled = audioInstalled, PublicationPath = PublicationPath("virtual-microphone-feed.json") };
        PublishOutputsIfPossible();
        RefreshSnapshot();
    }

    public void SetVirtualCameraStatus(
        bool isInstalled,
        bool isPublishing,
        IReadOnlyList<LayerKind>? lastPublishedLayerKinds = null,
        string? publicationPath = null,
        string? lastError = null)
    {
        _virtualCamera = _virtualCamera with
        {
            IsInstalled = isInstalled,
            IsPublishing = isPublishing,
            LastPublishedLayerKinds = lastPublishedLayerKinds ?? _virtualCamera.LastPublishedLayerKinds,
            PublicationPath = publicationPath ?? _virtualCamera.PublicationPath ?? PublicationPath("public-output-scene.json"),
            LastError = lastError
        };
        RefreshSnapshot();
    }

    public void SetVirtualAudioStatus(
        bool isInstalled,
        bool isPublishing,
        double lastMasterLevel = 0,
        string? publicationPath = null,
        string? lastError = null)
    {
        _virtualAudio = _virtualAudio with
        {
            IsInstalled = isInstalled,
            IsPublishing = isPublishing,
            LastMasterLevel = lastMasterLevel,
            PublicationPath = publicationPath ?? _virtualAudio.PublicationPath ?? PublicationPath("virtual-microphone-feed.json"),
            LastError = lastError
        };
        RefreshSnapshot();
    }

    public void SaveSettings() => _settingsStore.Save(_settings, SettingsKey);

    private void ApplySettingsToEngines()
    {
        _audioEngine.SetInternalPianoEnabled(_settings.Audio.UseInternalPiano);
        _audioEngine.SetRoutingMode(ToRoutingMode(_settings.Audio.RoutingPreference));
        _audioEngine.SetMixProfile(new AudioMixProfile(_settings.Audio.PianoGain, _settings.Audio.SpeechGain, _settings.Audio.ExternalInstrumentGain));
        _overlayEngine.SetVisible(_settings.Overlay.IsVisible);
        _overlayEngine.SetShowLabels(_settings.Overlay.ShowLabels);
        _studioMonitorState = new StudioMonitorState(
            _settings.StudioMonitor.NotationEnabled,
            _settings.StudioMonitor.DiagnosticsEnabled,
            _settings.StudioMonitor.MetersEnabled,
            _settings.StudioMonitor.EventLogEnabled,
            _settings.StudioMonitor.LatencyIndicatorEnabled
        );
        SyncOverlayFrameFromLayout();
    }

    private void RefreshSnapshot()
    {
        SyncOverlayFrameFromLayout();
        _overlayEngine.Update(_midiEngine.State);

        var resolvedLayout = ResolvedLayout();
        var publicSceneViolations = LayoutEngine.ValidatePublicOutput(resolvedLayout);
        var publicScene = LayoutEngine.BuildScene(LayoutEngine.SanitizedForPublicOutput(resolvedLayout), RenderTarget.PublicOutput);
        var estimatedLatency = CalculateLatencyEstimate();
        var checklist = BuildSetupChecklist(resolvedLayout);
        var setupComplete = checklist.All(item => item.IsComplete);
        var diagnostics = DiagnosticsEngine.BuildReport(_permissions, _videoEngine.State, _midiEngine.State, _audioEngine.State, publicSceneViolations, _virtualCamera, _virtualAudio, setupComplete);
        var studioMonitor = BuildStudioMonitorSnapshot(resolvedLayout, diagnostics, estimatedLatency);

        Snapshot = new FlowPianoRuntimeSnapshot(
            _settings,
            _permissions,
            _videoEngine.State,
            _midiEngine.State,
            _audioEngine.State,
            _notationEngine.State,
            _overlayEngine.State,
            diagnostics,
            publicScene,
            studioMonitor,
            _virtualCamera,
            _virtualAudio,
            checklist,
            publicSceneViolations,
            estimatedLatency
        );
    }

    private StudioMonitorSnapshot BuildStudioMonitorSnapshot(LayoutConfiguration layout, DiagnosticsReport diagnostics, double latency) =>
        new(
            LayoutEngine.VisibleLayers(layout, RenderTarget.StudioMonitor)
                .Select(layer => layer.Kind)
                .Where(kind => kind switch
                {
                    LayerKind.MusicStaff => _studioMonitorState.NotationEnabled,
                    LayerKind.AudioMeters => _studioMonitorState.MetersEnabled,
                    LayerKind.MidiEventLog => _studioMonitorState.EventLogEnabled,
                    LayerKind.LatencyIndicator => _studioMonitorState.LatencyIndicatorEnabled,
                    LayerKind.Diagnostics => _studioMonitorState.DiagnosticsEnabled,
                    _ => true
                })
                .ToArray(),
            _studioMonitorState.NotationEnabled ? _notationEngine.State : null,
            _studioMonitorState.MetersEnabled ? _audioEngine.State.Meters : null,
            _studioMonitorState.EventLogEnabled ? _midiEngine.State.EventLog.ToArray() : Array.Empty<MidiEventLogEntry>(),
            _studioMonitorState.DiagnosticsEnabled ? diagnostics : null,
            _studioMonitorState.LatencyIndicatorEnabled ? latency : null
        );

    private IReadOnlyList<SetupChecklistItem> BuildSetupChecklist(LayoutConfiguration resolvedLayout)
    {
        var overlayFrame = _settings.Layout.Layers.FirstOrDefault(layer => layer.Kind == LayerKind.MidiOverlay)?.Frame;
        var hasSecondCameraOption = _videoEngine.State.Devices.Count(device => device.IsAvailable) > 1 && _videoEngine.State.Capabilities.SupportsMultiCam;
        var notationVisibleOnlyInStudio = !LayoutEngine.VisibleLayers(resolvedLayout, RenderTarget.PublicOutput).Any(layer => layer.Kind == LayerKind.MusicStaff)
            && LayoutEngine.VisibleLayers(resolvedLayout, RenderTarget.StudioMonitor).Any(layer => layer.Kind == LayerKind.MusicStaff);
        var virtualDevicesComplete = (!_settings.VirtualDevices.AutoPublishCamera || _virtualCamera.IsInstalled)
            && (!_settings.VirtualDevices.AutoPublishMicrophone || _virtualAudio.IsInstalled);

        return
        [
            new SetupChecklistItem(SetupStep.Permissions, _permissions.CameraGranted && _permissions.MicrophoneGranted, "Camera and microphone permissions must be granted."),
            new SetupChecklistItem(SetupStep.MainCamera, _videoEngine.State.Assignment.MainCameraId is not null, "A main camera must be selected for the public output."),
            new SetupChecklistItem(SetupStep.PipCamera, !hasSecondCameraOption || _videoEngine.State.Assignment.PipCameraId is not null, "Choose a second camera when hardware supports picture-in-picture."),
            new SetupChecklistItem(SetupStep.MidiKeyboard, _midiEngine.State.IsConnected, "A MIDI keyboard should be connected and discoverable."),
            new SetupChecklistItem(SetupStep.InternalPiano, _audioEngine.State.InternalPianoEnabled && _audioEngine.State.IsRunning, "Internal piano mode should be enabled and audio running."),
            new SetupChecklistItem(SetupStep.OverlayPlacement, _settings.Overlay.IsVisible && overlayFrame is not null && overlayFrame.Width >= 600 && overlayFrame.Height >= 80, "The MIDI overlay must be visible and large enough to teach from."),
            new SetupChecklistItem(SetupStep.StudioNotation, _studioMonitorState.NotationEnabled && notationVisibleOnlyInStudio, "Notation must remain local-only on the Studio Monitor."),
            new SetupChecklistItem(SetupStep.VirtualDevices, virtualDevicesComplete, "Install the virtual camera and microphone when they are required.")
        ];
    }

    private LayoutConfiguration ResolvedLayout() =>
        new(
            _settings.Layout.Layers
                .Select(layer =>
                {
                    return layer.Kind switch
                    {
                        LayerKind.MidiOverlay => layer with { Visibility = layer.Visibility with { PublicVisible = _settings.Overlay.IsVisible, StudioVisible = _settings.Overlay.IsVisible } },
                        LayerKind.MusicStaff => layer with { Visibility = layer.Visibility with { StudioVisible = _studioMonitorState.NotationEnabled } },
                        LayerKind.AudioMeters => layer with { Visibility = layer.Visibility with { StudioVisible = _studioMonitorState.MetersEnabled } },
                        LayerKind.MidiEventLog => layer with { Visibility = layer.Visibility with { StudioVisible = _studioMonitorState.EventLogEnabled } },
                        LayerKind.LatencyIndicator => layer with { Visibility = layer.Visibility with { StudioVisible = _studioMonitorState.LatencyIndicatorEnabled } },
                        LayerKind.Diagnostics => layer with { Visibility = layer.Visibility with { StudioVisible = _studioMonitorState.DiagnosticsEnabled } },
                        _ => layer
                    };
                })
                .ToArray()
        );

    private void PublishOutputsIfPossible()
    {
        var publicScene = LayoutEngine.BuildScene(LayoutEngine.SanitizedForPublicOutput(ResolvedLayout()), RenderTarget.PublicOutput);

        if (_settings.VirtualDevices.AutoPublishCamera && _virtualCamera.IsInstalled)
        {
            WriteJson(_virtualCamera.PublicationPath, publicScene);
            _virtualCamera = _virtualCamera with
            {
                IsPublishing = true,
                LastPublishedLayerKinds = publicScene.Layers.Select(layer => layer.Kind).ToArray(),
                LastError = null
            };
        }

        if (_settings.VirtualDevices.AutoPublishMicrophone && _virtualAudio.IsInstalled && _audioEngine.State.IsRunning)
        {
            WriteJson(_virtualAudio.PublicationPath, new VirtualMicrophoneFeed(_audioEngine.State.ActiveNotes, _audioEngine.State.Meters));
            _virtualAudio = _virtualAudio with
            {
                IsPublishing = true,
                LastMasterLevel = _audioEngine.State.Meters.MasterLevel,
                LastError = null
            };
        }
    }

    private void SyncOverlayFrameFromLayout()
    {
        var overlayFrame = _settings.Layout.Layers.FirstOrDefault(layer => layer.Kind == LayerKind.MidiOverlay)?.Frame;
        if (overlayFrame is not null)
        {
            _overlayEngine.SetFrame(overlayFrame);
        }
    }

    private void PersistSettings()
    {
        try
        {
            _settingsStore.Save(_settings, SettingsKey);
        }
        catch
        {
        }
    }

    private static string PublicationPath(string fileName)
    {
        var directory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "FlowPiano", "Runtime");
        return Path.Combine(directory, fileName);
    }

    private static void WriteJson<T>(string? path, T payload)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return;
        }

        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        File.WriteAllText(path, JsonSerializer.Serialize(payload, new JsonSerializerOptions(JsonSerializerDefaults.Web) { WriteIndented = true }));
    }

    private static AudioRoutingMode ToRoutingMode(AudioRoutingPreference preference) => preference switch
    {
        AudioRoutingPreference.InternalOnly => AudioRoutingMode.InternalOnly,
        AudioRoutingPreference.Layered => AudioRoutingMode.Layered,
        AudioRoutingPreference.ExternalOnly => AudioRoutingMode.ExternalOnly,
        _ => AudioRoutingMode.InternalOnly
    };

    private static AudioRoutingPreference ToPreference(AudioRoutingMode mode) => mode switch
    {
        AudioRoutingMode.InternalOnly => AudioRoutingPreference.InternalOnly,
        AudioRoutingMode.Layered => AudioRoutingPreference.Layered,
        AudioRoutingMode.ExternalOnly => AudioRoutingPreference.ExternalOnly,
        _ => AudioRoutingPreference.InternalOnly
    };

    private double CalculateLatencyEstimate()
    {
        var cameraCost = _videoEngine.State.Mode == VideoMode.DualCamera ? 18d : 12d;
        var midiCost = _midiEngine.State.IsConnected ? 4d : 0d;
        var audioCost = _audioEngine.State.InternalPianoEnabled ? 6d : 3d;
        return cameraCost + midiCost + audioCost;
    }
}
