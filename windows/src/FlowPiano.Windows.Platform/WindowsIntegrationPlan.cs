using FlowPiano.Windows.Core;

namespace FlowPiano.Windows.Platform;

public interface IWindowsVideoCaptureService
{
    IReadOnlyList<CameraDevice> EnumerateCameras();
    VideoCapabilities QueryCapabilities();
    VideoRuntimeState QueryRuntimeState();
    void StartCapture(CameraAssignment assignment);
    void StopCapture();
}

public interface IWindowsMidiInputService
{
    IReadOnlyList<MidiDevice> EnumerateDevices();
    void Connect(string? deviceId);
    void Disconnect();
    event EventHandler<MidiEvent>? MidiEventReceived;
}

public interface IWindowsAudioRuntimeService
{
    AudioRuntimeState QueryRuntimeState();
    void Start(AudioMixProfile mixProfile);
    void Stop();
    void SetRouting(AudioRoutingMode mode, bool internalPianoEnabled);
    void HandleMidiEvent(MidiEvent midiEvent);
}

public interface IWindowsVirtualCameraPublisher
{
    bool IsInstalled { get; }
    bool IsPublishing { get; }
    string PublicationPath { get; }
    string BridgePath { get; }
    string ManifestPath { get; }
    string? LastError { get; }
    void Refresh();
    void Publish(RenderScene scene);
}

public interface IWindowsVirtualMicrophonePublisher
{
    bool IsInstalled { get; }
    bool IsPublishing { get; }
    string PublicationPath { get; }
    string BridgePath { get; }
    string ManifestPath { get; }
    string? LastError { get; }
    void Refresh();
    void Publish(VirtualMicrophoneFeed feed);
}

public static class WindowsApiPlan
{
    public static readonly string[] RecommendedBuildingBlocks =
    [
        "Media Foundation for camera enumeration and capture",
        "Windows virtual camera support through Media Foundation virtual camera APIs",
        "WinMM as broad-compatibility MIDI baseline with an abstraction for Windows MIDI Services",
        "WASAPI for render and speech input",
        "A dedicated virtual audio driver path for the publishable microphone device"
    ];
}
