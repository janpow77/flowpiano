using System.Text.Json;
using FlowPiano.Windows.Core;
using FlowPiano.Windows.Platform;
using Xunit;

namespace FlowPiano.Windows.Tests;

public sealed class PlatformBridgeTests
{
    [Fact]
    public void CompositeVideoCaptureFallsBackWhenPrimaryReturnsNoDevices()
    {
        var primary = new StubVideoCaptureService(Array.Empty<CameraDevice>(), new VideoCapabilities(false, 1), new VideoRuntimeState(false, false, false, "Primary unavailable."));
        var fallbackCamera = new CameraDevice("fallback-main", "Fallback Camera", CameraPosition.External);
        var fallback = new StubVideoCaptureService([fallbackCamera], new VideoCapabilities(false, 1), new VideoRuntimeState(true, true, false));
        var composite = new CompositeVideoCaptureService(primary, fallback);

        var cameras = composite.EnumerateCameras();

        Assert.Single(cameras);
        Assert.Equal("fallback-main", cameras[0].Id);
        Assert.True(composite.QueryRuntimeState().PlatformVideoAvailable);
    }

    [Fact]
    public void CaptureSessionWriterCreatesStableManifest()
    {
        var runtimeDirectory = CreateTempDirectory();
        try
        {
            var coordinator = new FlowPianoSessionCoordinator();
            coordinator.InstallPreviewHardwareProfile();
            coordinator.StartSession();

            var writer = new WindowsCaptureSessionWriter(runtimeDirectory);
            writer.Publish(coordinator.Snapshot, "Runtime ready", null, usingPreviewVideoFallback: true);

            var json = File.ReadAllText(writer.ManifestPath);
            using var document = JsonDocument.Parse(json);
            var root = document.RootElement;
            var scenePath = root.GetProperty("publicOutput").GetProperty("scenePath").GetString();

            Assert.Equal("Runtime ready", root.GetProperty("runtimeDescription").GetString());
            Assert.True(root.GetProperty("usingPreviewVideoFallback").GetBoolean());
            Assert.NotNull(scenePath);
            Assert.EndsWith(WindowsRuntimeArtifacts.PublicOutputSceneFileName, scenePath);
        }
        finally
        {
            Directory.Delete(runtimeDirectory, recursive: true);
        }
    }

    [Fact]
    public void VirtualCameraPublisherWritesSceneFeedAndBridgeDescriptor()
    {
        var runtimeDirectory = CreateTempDirectory();
        try
        {
            var publisher = new MediaFoundationVirtualCameraPublisher(runtimeDirectory);
            var scene = new RenderScene(RenderTarget.PublicOutput, [new RenderedLayer(LayerKind.MainCamera, new LayerFrame(0, 0, 1920, 1080), 0)]);

            publisher.Publish(scene);

            Assert.True(File.Exists(publisher.PublicationPath));
            Assert.True(File.Exists(publisher.BridgePath));

            using var document = JsonDocument.Parse(File.ReadAllText(publisher.BridgePath));
            var root = document.RootElement;
            var captureSessionPath = root.GetProperty("captureSessionPath").GetString();
            Assert.Equal("FlowPiano Virtual Camera", root.GetProperty("friendlyName").GetString());
            Assert.NotNull(captureSessionPath);
            Assert.EndsWith(WindowsRuntimeArtifacts.VirtualCameraCaptureSessionFileName, captureSessionPath);
        }
        finally
        {
            Directory.Delete(runtimeDirectory, recursive: true);
        }
    }

    private static string CreateTempDirectory()
    {
        var path = Path.Combine(Path.GetTempPath(), $"flowpiano-windows-tests-{Guid.NewGuid():N}");
        Directory.CreateDirectory(path);
        return path;
    }

    private sealed class StubVideoCaptureService : IWindowsVideoCaptureService
    {
        private readonly IReadOnlyList<CameraDevice> _cameras;
        private readonly VideoCapabilities _capabilities;
        private readonly VideoRuntimeState _runtime;

        public StubVideoCaptureService(IReadOnlyList<CameraDevice> cameras, VideoCapabilities capabilities, VideoRuntimeState runtime)
        {
            _cameras = cameras;
            _capabilities = capabilities;
            _runtime = runtime;
        }

        public IReadOnlyList<CameraDevice> EnumerateCameras() => _cameras;

        public VideoCapabilities QueryCapabilities() => _capabilities;

        public VideoRuntimeState QueryRuntimeState() => _runtime;

        public void StartCapture(CameraAssignment assignment)
        {
        }

        public void StopCapture()
        {
        }
    }
}
