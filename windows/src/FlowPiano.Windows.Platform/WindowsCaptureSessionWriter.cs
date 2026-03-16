using System.Text.Json;
using FlowPiano.Windows.Core;

namespace FlowPiano.Windows.Platform;

public sealed class WindowsCaptureSessionWriter
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { WriteIndented = true };

    public WindowsCaptureSessionWriter(string runtimeDirectory)
    {
        RuntimeDirectory = runtimeDirectory;
        ManifestPath = WindowsRuntimeArtifacts.PathFor(runtimeDirectory, WindowsRuntimeArtifacts.VirtualCameraCaptureSessionFileName);
    }

    public string RuntimeDirectory { get; }
    public string ManifestPath { get; }

    public void Publish(FlowPianoRuntimeSnapshot snapshot, string runtimeDescription, string? platformError, bool usingPreviewVideoFallback)
    {
        Directory.CreateDirectory(RuntimeDirectory);

        File.WriteAllText(ManifestPath, JsonSerializer.Serialize(new
        {
            publishedAtUtc = DateTimeOffset.UtcNow,
            runtimeDescription,
            platformError,
            usingPreviewVideoFallback,
            selectedCameras = new
            {
                main = snapshot.Video.MainCamera,
                pip = snapshot.Video.PipCamera
            },
            assignment = snapshot.Video.Assignment,
            capabilities = snapshot.Video.Capabilities,
            runtime = snapshot.Video.Runtime,
            publicOutput = new
            {
                scenePath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.PublicOutputSceneFileName),
                previewSvgPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.PublicOutputPreviewSvgFileName),
                previewHtmlPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.PublicOutputPreviewHtmlFileName),
                sceneLayerKinds = snapshot.PublicScene.Layers.Select(layer => layer.Kind).ToArray()
            },
            runtimeStatusPath = WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.RuntimeStatusFileName)
        }, JsonOptions));
    }
}
