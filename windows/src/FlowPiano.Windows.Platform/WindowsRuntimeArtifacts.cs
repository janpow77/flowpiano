namespace FlowPiano.Windows.Platform;

public static class WindowsRuntimeArtifacts
{
    public const string PublicOutputSceneFileName = "public-output-scene.json";
    public const string PublicOutputPreviewSvgFileName = "public-output-preview.svg";
    public const string PublicOutputPreviewHtmlFileName = "public-output-preview.html";
    public const string StudioMonitorPreviewSvgFileName = "studio-monitor-preview.svg";
    public const string RuntimeStatusFileName = "runtime-status.json";
    public const string VirtualMicrophoneFeedFileName = "virtual-microphone-feed.json";
    public const string VirtualMicrophonePreviewFileName = "virtual-microphone-preview.txt";
    public const string VirtualCameraBridgeFileName = "virtual-camera-bridge.json";
    public const string VirtualCameraRegistrationFileName = "virtual-camera-registration.json";
    public const string VirtualCameraCaptureSessionFileName = "camera-capture-session.json";
    public const string VirtualCameraRegistrationScriptFileName = "register-virtual-camera.ps1";
    public const string VirtualAudioDriverBridgeFileName = "virtual-microphone-driver-feed.json";
    public const string VirtualAudioDriverManifestFileName = "virtual-audio-driver-manifest.json";
    public const string VirtualAudioDriverInstallerHintFileName = "install-virtual-audio-driver.txt";

    public static string PathFor(string runtimeDirectory, string fileName) =>
        Path.Combine(runtimeDirectory, fileName);
}
