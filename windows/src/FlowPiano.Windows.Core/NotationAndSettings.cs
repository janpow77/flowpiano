using System.Text.Json;

namespace FlowPiano.Windows.Core;

public enum NotationDisplayMode
{
    Scrolling,
    StaticMapping
}

public sealed record StaffSymbol(int Id, int Note, string NoteName, int Octave, int Velocity, bool IsActive);

public sealed class NotationState
{
    public NotationDisplayMode DisplayMode { get; set; } = NotationDisplayMode.Scrolling;
    public List<StaffSymbol> ActiveSymbols { get; set; } = [];
    public List<StaffSymbol> RecentSymbols { get; set; } = [];
}

public sealed class NotationEngine
{
    private readonly Dictionary<int, StaffSymbol> _activeByNote = [];
    private int _nextSymbolId = 1;

    public NotationState State { get; } = new();

    public void Consume(MidiEvent midiEvent)
    {
        if (midiEvent.IsNoteOn && midiEvent.Velocity > 0)
        {
            _activeByNote[midiEvent.Note] = new StaffSymbol(
                _nextSymbolId++,
                midiEvent.Note,
                NoteName(midiEvent.Note),
                Octave(midiEvent.Note),
                midiEvent.Velocity,
                true
            );
        }
        else if (_activeByNote.Remove(midiEvent.Note, out var symbol))
        {
            State.RecentSymbols.Insert(0, symbol with { IsActive = false });
            if (State.RecentSymbols.Count > 16)
            {
                State.RecentSymbols.RemoveRange(16, State.RecentSymbols.Count - 16);
            }
        }

        State.ActiveSymbols = _activeByNote.Values.OrderBy(symbol => symbol.Note).ToList();
    }

    private static string NoteName(int note) => new[] { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }[((note % 12) + 12) % 12];
    private static int Octave(int note) => (note / 12) - 1;
}

public sealed class MidiOverlayState
{
    public bool IsVisible { get; set; } = true;
    public bool ShowLabels { get; set; } = true;
    public LayerFrame Frame { get; set; } = new(60, 900, 1800, 120);
    public List<OverlayKeyState> ActiveKeys { get; set; } = [];
}

public sealed record OverlayKeyState(int Note, int Velocity, bool IsActive);

public sealed class OverlayEngine
{
    public MidiOverlayState State { get; } = new();

    public void SetVisible(bool isVisible) => State.IsVisible = isVisible;
    public void SetShowLabels(bool showLabels) => State.ShowLabels = showLabels;
    public void SetFrame(LayerFrame frame) => State.Frame = frame;

    public void Update(MidiConnectionStatus midiStatus)
    {
        State.ActiveKeys = midiStatus.ActiveVelocities
            .OrderBy(entry => entry.Key)
            .Select(entry => new OverlayKeyState(entry.Key, entry.Value, true))
            .ToList();
    }
}

public enum AudioRoutingPreference
{
    InternalOnly,
    Layered,
    ExternalOnly
}

public sealed record VideoSettings(string? PreferredMainCameraId = null, string? PreferredPipCameraId = null, bool AllowMultiCamFallback = true);
public sealed record AudioSettings(bool UseInternalPiano = true, AudioRoutingPreference RoutingPreference = AudioRoutingPreference.InternalOnly, double PianoGain = 0.9, double SpeechGain = 0.8, double ExternalInstrumentGain = 0.7);
public sealed record MidiSettings(string? PreferredInputDeviceId = null, bool AutoReconnect = true);
public sealed record OverlaySettings(bool IsVisible = true, bool ShowLabels = true);
public sealed record StudioMonitorSettings(bool NotationEnabled = true, bool DiagnosticsEnabled = true, bool MetersEnabled = true, bool EventLogEnabled = true, bool LatencyIndicatorEnabled = true);
public sealed record VirtualDeviceSettings(bool AutoPublishCamera = true, bool AutoPublishMicrophone = true);

public sealed record AppSettings(
    LayoutConfiguration Layout,
    VideoSettings Video,
    AudioSettings Audio,
    MidiSettings Midi,
    OverlaySettings Overlay,
    StudioMonitorSettings StudioMonitor,
    VirtualDeviceSettings VirtualDevices
)
{
    public static AppSettings Default { get; } = new(
        LayoutConfiguration.Default,
        new VideoSettings(),
        new AudioSettings(),
        new MidiSettings(),
        new OverlaySettings(),
        new StudioMonitorSettings(),
        new VirtualDeviceSettings()
    );
}

public interface ISettingsStore
{
    void Save<T>(T value, string key);
    T? Load<T>(string key);
}

public sealed class InMemorySettingsStore : ISettingsStore
{
    private readonly Dictionary<string, string> _values = [];
    private readonly JsonSerializerOptions _json = new(JsonSerializerDefaults.Web);

    public void Save<T>(T value, string key) => _values[key] = JsonSerializer.Serialize(value, _json);

    public T? Load<T>(string key) => _values.TryGetValue(key, out var json)
        ? JsonSerializer.Deserialize<T>(json, _json)
        : default;
}

public sealed class FileSettingsStore(string directoryPath) : ISettingsStore
{
    private readonly JsonSerializerOptions _json = new(JsonSerializerDefaults.Web) { WriteIndented = true };

    public void Save<T>(T value, string key)
    {
        Directory.CreateDirectory(directoryPath);
        var path = Path.Combine(directoryPath, $"{key}.json");
        File.WriteAllText(path, JsonSerializer.Serialize(value, _json));
    }

    public T? Load<T>(string key)
    {
        var path = Path.Combine(directoryPath, $"{key}.json");
        return File.Exists(path)
            ? JsonSerializer.Deserialize<T>(File.ReadAllText(path), _json)
            : default;
    }
}
