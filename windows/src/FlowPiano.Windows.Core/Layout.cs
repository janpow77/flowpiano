namespace FlowPiano.Windows.Core;

public enum RenderTarget
{
    PublicOutput,
    StudioMonitor
}

public sealed record LayerFrame
{
    public LayerFrame(double x, double y, double width, double height)
    {
        X = x;
        Y = y;
        Width = Math.Max(width, 1);
        Height = Math.Max(height, 1);
    }

    public double X { get; init; }
    public double Y { get; init; }
    public double Width { get; init; }
    public double Height { get; init; }

    public LayerFrame Moved(double x, double y) => this with { X = x, Y = y };
    public LayerFrame Resized(double width, double height) => this with { Width = width, Height = height };
}

public sealed record LayerVisibilityPolicy(bool PublicVisible, bool StudioVisible);

public enum LayerKind
{
    MainCamera,
    PipCamera,
    MidiOverlay,
    MusicStaff,
    AudioMeters,
    MidiEventLog,
    LatencyIndicator,
    Diagnostics
}

public sealed record LayoutLayer(LayerKind Kind, LayerFrame Frame, int ZIndex, LayerVisibilityPolicy Visibility);

public sealed record RenderedLayer(LayerKind Kind, LayerFrame Frame, int ZIndex);

public sealed record RenderScene(RenderTarget Target, IReadOnlyList<RenderedLayer> Layers);

public sealed record LayoutConfiguration(IReadOnlyList<LayoutLayer> Layers)
{
    public static LayoutConfiguration Default { get; } = new([
        new LayoutLayer(LayerKind.MainCamera, new LayerFrame(0, 0, 1920, 1080), 0, new LayerVisibilityPolicy(true, true)),
        new LayoutLayer(LayerKind.PipCamera, new LayerFrame(1420, 40, 440, 248), 10, new LayerVisibilityPolicy(true, true)),
        new LayoutLayer(LayerKind.MidiOverlay, new LayerFrame(60, 900, 1800, 120), 20, new LayerVisibilityPolicy(true, true)),
        new LayoutLayer(LayerKind.MusicStaff, new LayerFrame(60, 720, 1800, 140), 30, new LayerVisibilityPolicy(false, true)),
        new LayoutLayer(LayerKind.AudioMeters, new LayerFrame(1280, 320, 580, 90), 31, new LayerVisibilityPolicy(false, true)),
        new LayoutLayer(LayerKind.MidiEventLog, new LayerFrame(1280, 430, 580, 150), 32, new LayerVisibilityPolicy(false, true)),
        new LayoutLayer(LayerKind.LatencyIndicator, new LayerFrame(1280, 600, 300, 60), 33, new LayerVisibilityPolicy(false, true)),
        new LayoutLayer(LayerKind.Diagnostics, new LayerFrame(60, 40, 700, 180), 40, new LayerVisibilityPolicy(false, true))
    ]);
}

public static class LayoutEngine
{
    public static IReadOnlyList<LayoutLayer> VisibleLayers(LayoutConfiguration configuration, RenderTarget target) =>
        configuration.Layers
            .Where(layer => target == RenderTarget.PublicOutput ? layer.Visibility.PublicVisible : layer.Visibility.StudioVisible)
            .OrderBy(layer => layer.ZIndex)
            .ToArray();

    public static RenderScene BuildScene(LayoutConfiguration configuration, RenderTarget target) =>
        new(
            target,
            VisibleLayers(configuration, target)
                .Select(layer => new RenderedLayer(layer.Kind, layer.Frame, layer.ZIndex))
                .ToArray()
        );

    public static IReadOnlyList<LayerKind> ValidatePublicOutput(LayoutConfiguration configuration) =>
        VisibleLayers(configuration, RenderTarget.PublicOutput)
            .Select(layer => layer.Kind)
            .Where(kind => !IsPublicSafe(kind))
            .ToArray();

    public static LayoutConfiguration SanitizedForPublicOutput(LayoutConfiguration configuration) =>
        new(
            configuration.Layers
                .Select(layer => IsPublicSafe(layer.Kind)
                    ? layer
                    : layer with { Visibility = layer.Visibility with { PublicVisible = false } })
                .ToArray()
        );

    public static LayoutConfiguration MoveLayer(LayoutConfiguration configuration, LayerKind kind, double x, double y) =>
        UpdateFrame(configuration, kind, frame => frame.Moved(x, y));

    public static LayoutConfiguration ResizeLayer(LayoutConfiguration configuration, LayerKind kind, double width, double height) =>
        UpdateFrame(configuration, kind, frame => frame.Resized(width, height));

    public static LayoutConfiguration SwapCameraFrames(LayoutConfiguration configuration)
    {
        var main = configuration.Layers.FirstOrDefault(layer => layer.Kind == LayerKind.MainCamera);
        var pip = configuration.Layers.FirstOrDefault(layer => layer.Kind == LayerKind.PipCamera);

        if (main is null || pip is null)
        {
            return configuration;
        }

        return new LayoutConfiguration(
            configuration.Layers
                .Select(layer => layer.Kind switch
                {
                    LayerKind.MainCamera => layer with { Frame = pip.Frame },
                    LayerKind.PipCamera => layer with { Frame = main.Frame },
                    _ => layer
                })
                .ToArray()
        );
    }

    public static bool IsPublicSafe(LayerKind kind) => kind is LayerKind.MainCamera or LayerKind.PipCamera or LayerKind.MidiOverlay;

    private static LayoutConfiguration UpdateFrame(LayoutConfiguration configuration, LayerKind kind, Func<LayerFrame, LayerFrame> update) =>
        new(
            configuration.Layers
                .Select(layer => layer.Kind == kind ? layer with { Frame = update(layer.Frame) } : layer)
                .ToArray()
        );
}
