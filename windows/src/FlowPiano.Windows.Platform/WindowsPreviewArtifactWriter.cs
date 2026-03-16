using System.Text;
using System.Text.Json;
using FlowPiano.Windows.Core;

namespace FlowPiano.Windows.Platform;

public sealed class WindowsPreviewArtifactWriter
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { WriteIndented = true };

    public WindowsPreviewArtifactWriter(string runtimeDirectory)
    {
        RuntimeDirectory = runtimeDirectory;
    }

    public string RuntimeDirectory { get; }

    public void Publish(FlowPianoRuntimeSnapshot snapshot, string runtimeDescription, string? platformError, bool usingPreviewVideoFallback)
    {
        Directory.CreateDirectory(RuntimeDirectory);

        WriteJson(WindowsRuntimeArtifacts.PublicOutputSceneFileName, snapshot.PublicScene);
        WriteJson(WindowsRuntimeArtifacts.VirtualMicrophoneFeedFileName, new VirtualMicrophoneFeed(snapshot.Audio.ActiveNotes, snapshot.Audio.Meters));
        WriteJson(WindowsRuntimeArtifacts.RuntimeStatusFileName, new
        {
            runtimeDescription,
            platformError,
            usingPreviewVideoFallback,
            video = snapshot.Video,
            midi = snapshot.Midi,
            audio = snapshot.Audio.Runtime,
            diagnostics = snapshot.Diagnostics
        });

        File.WriteAllText(WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.PublicOutputPreviewSvgFileName), BuildPublicOutputSvg(snapshot));
        File.WriteAllText(WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.StudioMonitorPreviewSvgFileName), BuildStudioMonitorSvg(snapshot));
        File.WriteAllText(WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.PublicOutputPreviewHtmlFileName), BuildPublicOutputHtml(snapshot, runtimeDescription, platformError, usingPreviewVideoFallback));
        File.WriteAllText(WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, WindowsRuntimeArtifacts.VirtualMicrophonePreviewFileName), BuildAudioPreview(snapshot));
    }

    private void WriteJson<T>(string fileName, T payload)
    {
        File.WriteAllText(WindowsRuntimeArtifacts.PathFor(RuntimeDirectory, fileName), JsonSerializer.Serialize(payload, JsonOptions));
    }

    private static string BuildPublicOutputSvg(FlowPianoRuntimeSnapshot snapshot)
    {
        var builder = BeginSvg("FlowPiano Public Output");
        foreach (var layer in snapshot.PublicScene.Layers.OrderBy(layer => layer.ZIndex))
        {
            AppendLayer(builder, layer.Kind, layer.Frame, layer.ZIndex);
        }

        AppendFooter(
            builder,
            $"Main Camera: {snapshot.Video.MainCamera?.Name ?? "None"} | PiP: {snapshot.Video.PipCamera?.Name ?? "None"}",
            $"MIDI: {snapshot.Midi.ConnectedDevice?.Name ?? "Disconnected"} | Notes: {FormatNotes(snapshot.Audio.ActiveNotes)}");

        EndSvg(builder);
        return builder.ToString();
    }

    private static string BuildStudioMonitorSvg(FlowPianoRuntimeSnapshot snapshot)
    {
        var visibleKinds = snapshot.StudioMonitor.VisibleLayers.ToHashSet();
        var layers = snapshot.Settings.Layout.Layers
            .Where(layer => visibleKinds.Contains(layer.Kind))
            .OrderBy(layer => layer.ZIndex)
            .ToArray();

        var builder = BeginSvg("FlowPiano Studio Monitor");
        foreach (var layer in layers)
        {
            AppendLayer(builder, layer.Kind, layer.Frame, layer.ZIndex);
        }

        AppendFooter(
            builder,
            $"Diagnostics: {snapshot.Diagnostics.Issues.Count} | Latency: {snapshot.EstimatedLatencyMilliseconds:0.#} ms",
            $"Notation: {snapshot.Notation.ActiveSymbols.Count} active | Recent: {snapshot.Notation.RecentSymbols.Count}");

        EndSvg(builder);
        return builder.ToString();
    }

    private static string BuildPublicOutputHtml(FlowPianoRuntimeSnapshot snapshot, string runtimeDescription, string? platformError, bool usingPreviewVideoFallback)
    {
        var publicSvg = BuildPublicOutputSvg(snapshot);
        var diagnosticItems = string.Join(Environment.NewLine, snapshot.Diagnostics.Issues.Select(issue =>
            $"<li><strong>{Escape(issue.Code.ToString())}</strong>: {Escape(issue.Message)}<br/><span>{Escape(issue.RecoverySuggestion)}</span></li>"));

        return $$"""
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>FlowPiano Windows Preview</title>
  <style>
    body { font-family: "Segoe UI", sans-serif; margin: 24px; background: #0f1720; color: #e7edf2; }
    .card { background: #132433; border: 1px solid #23445f; border-radius: 16px; padding: 20px; margin-bottom: 18px; }
    h1, h2 { margin: 0 0 12px; }
    p, li { line-height: 1.45; }
    code { color: #9fe6ff; }
    svg { width: 100%; height: auto; border-radius: 14px; background: #071019; }
  </style>
</head>
<body>
  <div class="card">
    <h1>FlowPiano Windows Preview</h1>
    <p>{{Escape(runtimeDescription)}}</p>
    <p>Video fallback active: <strong>{{usingPreviewVideoFallback}}</strong></p>
    <p>Platform status: <strong>{{Escape(platformError ?? "No platform error")}}</strong></p>
  </div>
  <div class="card">
    <h2>Public Output</h2>
    {{publicSvg}}
  </div>
  <div class="card">
    <h2>Diagnostics</h2>
    <ul>
      {{diagnosticItems}}
    </ul>
  </div>
</body>
</html>
""";
    }

    private static string BuildAudioPreview(FlowPianoRuntimeSnapshot snapshot)
    {
        var builder = new StringBuilder();
        builder.AppendLine("FlowPiano Windows Virtual Microphone Preview");
        builder.AppendLine($"Routing: {snapshot.Audio.RoutingMode}");
        builder.AppendLine($"Internal Piano: {snapshot.Audio.InternalPianoEnabled}");
        builder.AppendLine($"Piano Bank: {snapshot.Audio.Runtime.PianoSoundBankName}");
        builder.AppendLine($"Active Notes: {FormatNotes(snapshot.Audio.ActiveNotes)}");
        builder.AppendLine($"Piano Level: {snapshot.Audio.Meters.PianoLevel:0.00}");
        builder.AppendLine($"Speech Level: {snapshot.Audio.Meters.SpeechLevel:0.00}");
        builder.AppendLine($"External Level: {snapshot.Audio.Meters.ExternalLevel:0.00}");
        builder.AppendLine($"Master Level: {snapshot.Audio.Meters.MasterLevel:0.00}");
        return builder.ToString();
    }

    private static StringBuilder BeginSvg(string title)
    {
        var builder = new StringBuilder();
        builder.AppendLine("""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" role="img">""");
        builder.AppendLine("""  <defs>""");
        builder.AppendLine("""    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">""");
        builder.AppendLine("""      <stop offset="0%" stop-color="#0f2030" />""");
        builder.AppendLine("""      <stop offset="100%" stop-color="#081018" />""");
        builder.AppendLine("""    </linearGradient>""");
        builder.AppendLine("""  </defs>""");
        builder.AppendLine("""  <rect width="1920" height="1080" fill="url(#bg)" rx="28" />""");
        builder.AppendLine($"""  <text x="64" y="88" fill="#f4f7fb" font-size="38" font-family="Segoe UI" font-weight="700">{Escape(title)}</text>""");
        return builder;
    }

    private static void AppendLayer(StringBuilder builder, LayerKind kind, LayerFrame frame, int zIndex)
    {
        var (fill, stroke) = LayerColors(kind);
        builder.AppendLine($"""  <rect x="{frame.X:0.##}" y="{frame.Y:0.##}" width="{frame.Width:0.##}" height="{frame.Height:0.##}" rx="24" fill="{fill}" stroke="{stroke}" stroke-width="4" />""");
        builder.AppendLine($"""  <text x="{frame.X + 24:0.##}" y="{frame.Y + 44:0.##}" fill="#ffffff" font-size="30" font-family="Segoe UI" font-weight="700">{Escape(kind.ToString())}</text>""");
        builder.AppendLine($"""  <text x="{frame.X + 24:0.##}" y="{frame.Y + 82:0.##}" fill="#d4e4ef" font-size="20" font-family="Segoe UI">z-index {zIndex}</text>""");
    }

    private static void AppendFooter(StringBuilder builder, string lineOne, string lineTwo)
    {
        builder.AppendLine("""  <rect x="48" y="952" width="1824" height="90" rx="24" fill="#081723" stroke="#2b5875" stroke-width="3" opacity="0.95" />""");
        builder.AppendLine($"""  <text x="80" y="995" fill="#f3f8fc" font-size="24" font-family="Segoe UI">{Escape(lineOne)}</text>""");
        builder.AppendLine($"""  <text x="80" y="1027" fill="#9dc5d9" font-size="21" font-family="Segoe UI">{Escape(lineTwo)}</text>""");
    }

    private static void EndSvg(StringBuilder builder) => builder.AppendLine("</svg>");

    private static (string Fill, string Stroke) LayerColors(LayerKind kind) => kind switch
    {
        LayerKind.MainCamera => ("#17436b", "#7ac8ff"),
        LayerKind.PipCamera => ("#395b2e", "#bbef7c"),
        LayerKind.MidiOverlay => ("#6a3d16", "#ffbe7b"),
        LayerKind.MusicStaff => ("#5f365e", "#f3a9ff"),
        LayerKind.AudioMeters => ("#334e24", "#b4ef75"),
        LayerKind.MidiEventLog => ("#6b2b31", "#ff9ea6"),
        LayerKind.LatencyIndicator => ("#2f5770", "#84d8ff"),
        LayerKind.Diagnostics => ("#714514", "#ffd073"),
        _ => ("#243342", "#9fb3c5")
    };

    private static string FormatNotes(IReadOnlyList<int> notes) =>
        notes.Count == 0 ? "none" : string.Join(", ", notes);

    private static string Escape(string? value) =>
        string.IsNullOrEmpty(value)
            ? string.Empty
            : value
                .Replace("&", "&amp;", StringComparison.Ordinal)
                .Replace("<", "&lt;", StringComparison.Ordinal)
                .Replace(">", "&gt;", StringComparison.Ordinal)
                .Replace("\"", "&quot;", StringComparison.Ordinal);
}
