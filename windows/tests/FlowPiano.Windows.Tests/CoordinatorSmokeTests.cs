using FlowPiano.Windows.Core;
using Xunit;

namespace FlowPiano.Windows.Tests;

public sealed class CoordinatorSmokeTests
{
    [Fact]
    public void PreviewProfileProducesReleaseReadySnapshot()
    {
        var coordinator = new FlowPianoSessionCoordinator();
        coordinator.InstallPreviewHardwareProfile();
        coordinator.StartSession();

        Assert.All(coordinator.Snapshot.SetupChecklist, item => Assert.True(item.IsComplete));
        Assert.True(coordinator.Snapshot.Diagnostics.IsReleaseReady);
        Assert.NotEqual(PianoSoundBankSource.Unavailable, coordinator.Snapshot.Audio.Runtime.PianoSoundBankSource);
    }

    [Fact]
    public void OverlayVisibilityRemovesOverlayFromPublicOutput()
    {
        var coordinator = new FlowPianoSessionCoordinator();
        coordinator.InstallPreviewHardwareProfile();
        coordinator.StartSession();

        coordinator.SetOverlayVisible(false);

        Assert.DoesNotContain(coordinator.Snapshot.PublicScene.Layers, layer => layer.Kind == LayerKind.MidiOverlay);
        Assert.DoesNotContain(LayerKind.MidiOverlay, coordinator.Snapshot.StudioMonitor.VisibleLayers);
    }

    [Fact]
    public void UnavailableAudioRuntimeRaisesPianoDiagnostic()
    {
        var coordinator = new FlowPianoSessionCoordinator();
        coordinator.InstallPreviewHardwareProfile();
        coordinator.StartSession();

        coordinator.SetAudioRuntime(new AudioRuntimeState(false, true, PianoSoundBankSource.Unavailable, "Unavailable"));

        Assert.Contains(coordinator.Snapshot.Diagnostics.Issues, issue => issue.Code == DiagnosticCode.MissingPianoSoundBank);
    }

    [Fact]
    public void VideoRuntimeCanBeInjectedIntoSnapshot()
    {
        var coordinator = new FlowPianoSessionCoordinator();
        coordinator.InstallPreviewHardwareProfile();
        coordinator.StartSession();

        coordinator.SetVideoRuntime(new VideoRuntimeState(false, true, false, "Preview fallback active."));

        Assert.False(coordinator.Snapshot.Video.Runtime.PlatformVideoAvailable);
        Assert.Equal("Preview fallback active.", coordinator.Snapshot.Video.Runtime.LastError);
    }

    [Fact]
    public void VirtualDeviceStatusesCanBeInjectedIntoSnapshot()
    {
        var coordinator = new FlowPianoSessionCoordinator();
        coordinator.InstallPreviewHardwareProfile();
        coordinator.StartSession();

        coordinator.SetVirtualCameraStatus(false, true, [LayerKind.MainCamera, LayerKind.MidiOverlay], "runtime/public-output-scene.json", "Bridge active.");
        coordinator.SetVirtualAudioStatus(false, true, 0.42, "runtime/virtual-microphone-feed.json", "Driver bridge active.");

        Assert.True(coordinator.Snapshot.VirtualCamera.IsPublishing);
        Assert.Equal("runtime/public-output-scene.json", coordinator.Snapshot.VirtualCamera.PublicationPath);
        Assert.Equal("Bridge active.", coordinator.Snapshot.VirtualCamera.LastError);
        Assert.True(coordinator.Snapshot.VirtualAudio.IsPublishing);
        Assert.Equal(0.42, coordinator.Snapshot.VirtualAudio.LastMasterLevel);
        Assert.Equal("runtime/virtual-microphone-feed.json", coordinator.Snapshot.VirtualAudio.PublicationPath);
    }
}
