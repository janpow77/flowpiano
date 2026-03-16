using FlowPiano.Windows.Core;
using Xunit;

namespace FlowPiano.Windows.Tests;

public sealed class LayoutVisibilityTests
{
    [Fact]
    public void StudioOnlyLayersAreExcludedFromPublicOutput()
    {
        var publicLayers = LayoutEngine.VisibleLayers(LayoutConfiguration.Default, RenderTarget.PublicOutput);

        Assert.DoesNotContain(publicLayers, layer => layer.Kind == LayerKind.MusicStaff);
        Assert.DoesNotContain(publicLayers, layer => layer.Kind == LayerKind.AudioMeters);
        Assert.DoesNotContain(publicLayers, layer => layer.Kind == LayerKind.MidiEventLog);
        Assert.DoesNotContain(publicLayers, layer => layer.Kind == LayerKind.LatencyIndicator);
        Assert.DoesNotContain(publicLayers, layer => layer.Kind == LayerKind.Diagnostics);
    }

    [Fact]
    public void ValidationDetectsPublicLeak()
    {
        var unsafeConfiguration = new LayoutConfiguration(
            LayoutConfiguration.Default.Layers.Select(layer =>
                layer.Kind == LayerKind.Diagnostics
                    ? layer with { Visibility = layer.Visibility with { PublicVisible = true } }
                    : layer).ToArray());

        Assert.Contains(LayerKind.Diagnostics, LayoutEngine.ValidatePublicOutput(unsafeConfiguration));
        Assert.Empty(LayoutEngine.ValidatePublicOutput(LayoutEngine.SanitizedForPublicOutput(unsafeConfiguration)));
    }
}
