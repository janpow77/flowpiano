namespace FlowPiano.Windows.Core;

public enum AudioRoutingMode
{
    InternalOnly,
    Layered,
    ExternalOnly
}

public enum PianoSoundBankSource
{
    BundledGeneralUserGs,
    WindowsSystemBank,
    Unavailable
}

public sealed record AudioMixProfile
{
    public AudioMixProfile(double pianoGain = 0.9, double speechGain = 0.8, double externalInstrumentGain = 0.7, double masterGain = 1.0)
    {
        PianoGain = Clamp(pianoGain);
        SpeechGain = Clamp(speechGain);
        ExternalInstrumentGain = Clamp(externalInstrumentGain);
        MasterGain = Clamp(masterGain);
    }

    public double PianoGain { get; init; }
    public double SpeechGain { get; init; }
    public double ExternalInstrumentGain { get; init; }
    public double MasterGain { get; init; }

    private static double Clamp(double value) => Math.Clamp(value, 0, 1);
}

public sealed record AudioMeterState(double PianoLevel = 0, double SpeechLevel = 0, double ExternalLevel = 0, double MasterLevel = 0);

public sealed record AudioRuntimeState(
    bool PlatformAudioAvailable,
    bool SpeechInputAvailable,
    PianoSoundBankSource PianoSoundBankSource,
    string PianoSoundBankName,
    string? LastError = null
)
{
    public static AudioRuntimeState Preview { get; } = new(true, true, PianoSoundBankSource.BundledGeneralUserGs, "GeneralUser GS v1.471");
}

public sealed class AudioEngineState
{
    public bool IsRunning { get; set; }
    public bool InternalPianoEnabled { get; set; } = true;
    public AudioRoutingMode RoutingMode { get; set; } = AudioRoutingMode.InternalOnly;
    public bool ExternalInstrumentConnected { get; set; }
    public AudioMixProfile MixProfile { get; set; } = new();
    public AudioMeterState Meters { get; set; } = new();
    public Dictionary<int, int> ActiveVelocities { get; set; } = [];
    public double SpeechInputLevel { get; set; }
    public AudioRuntimeState Runtime { get; set; } = AudioRuntimeState.Preview;

    public IReadOnlyList<int> ActiveNotes => ActiveVelocities.Keys.OrderBy(note => note).ToArray();
}

public sealed class AudioEngine
{
    public AudioEngineState State { get; } = new();

    public void SetRuntime(AudioRuntimeState runtime)
    {
        State.Runtime = runtime;
        UpdateMeters();
    }

    public void Start()
    {
        State.IsRunning = true;
        UpdateMeters();
    }

    public void Stop()
    {
        State.IsRunning = false;
        State.ActiveVelocities.Clear();
        UpdateMeters();
    }

    public void SetInternalPianoEnabled(bool enabled)
    {
        State.InternalPianoEnabled = enabled;
        if (!enabled)
        {
            State.ActiveVelocities.Clear();
        }

        UpdateMeters();
    }

    public void SetRoutingMode(AudioRoutingMode mode)
    {
        State.RoutingMode = mode;
        if (mode == AudioRoutingMode.ExternalOnly)
        {
            State.ActiveVelocities.Clear();
        }

        UpdateMeters();
    }

    public void SetMixProfile(AudioMixProfile profile)
    {
        State.MixProfile = profile;
        UpdateMeters();
    }

    public void SetSpeechInputLevel(double level)
    {
        State.SpeechInputLevel = Math.Clamp(level, 0, 1);
        UpdateMeters();
    }

    public void SetExternalInstrumentConnected(bool connected)
    {
        State.ExternalInstrumentConnected = connected;
        UpdateMeters();
    }

    public void Process(MidiEvent midiEvent)
    {
        if (!State.InternalPianoEnabled || State.RoutingMode == AudioRoutingMode.ExternalOnly)
        {
            UpdateMeters();
            return;
        }

        if (midiEvent.IsNoteOn && midiEvent.Velocity > 0)
        {
            State.ActiveVelocities[midiEvent.Note] = midiEvent.Velocity;
        }
        else
        {
            State.ActiveVelocities.Remove(midiEvent.Note);
        }

        UpdateMeters();
    }

    private void UpdateMeters()
    {
        var pianoSignal = 0.0;
        if (State.InternalPianoEnabled && State.RoutingMode != AudioRoutingMode.ExternalOnly && State.ActiveVelocities.Count > 0)
        {
            var averageVelocity = State.ActiveVelocities.Values.Average();
            pianoSignal = Math.Min((averageVelocity / 127d) * State.MixProfile.PianoGain, 1);
        }

        var speechSignal = Math.Min(State.SpeechInputLevel * State.MixProfile.SpeechGain, 1);
        var externalSignal = State.ExternalInstrumentConnected && State.RoutingMode != AudioRoutingMode.InternalOnly
            ? Math.Min(0.6 * State.MixProfile.ExternalInstrumentGain, 1)
            : 0;

        var masterSignal = Math.Min((pianoSignal + speechSignal + externalSignal) * State.MixProfile.MasterGain, 1);

        State.Meters = new AudioMeterState(
            pianoSignal,
            speechSignal,
            externalSignal,
            State.IsRunning ? masterSignal : 0
        );
    }
}
