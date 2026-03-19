namespace FlowPiano.Windows.Core;

// MARK: - PitchClass

public enum PitchClass
{
    C = 0, CSharp, D, DSharp, E, F, FSharp, G, GSharp, A, ASharp, B
}

public static class PitchClassExtensions
{
    public static readonly IReadOnlyList<PitchClass> AllCases =
        [PitchClass.C, PitchClass.CSharp, PitchClass.D, PitchClass.DSharp, PitchClass.E, PitchClass.F,
         PitchClass.FSharp, PitchClass.G, PitchClass.GSharp, PitchClass.A, PitchClass.ASharp, PitchClass.B];

    public static string GetName(this PitchClass pc) => pc switch
    {
        PitchClass.C => "C", PitchClass.CSharp => "C#", PitchClass.D => "D", PitchClass.DSharp => "D#",
        PitchClass.E => "E", PitchClass.F => "F", PitchClass.FSharp => "F#", PitchClass.G => "G",
        PitchClass.GSharp => "G#", PitchClass.A => "A", PitchClass.ASharp => "A#", PitchClass.B => "B",
        _ => "?"
    };

    public static string GetGermanName(this PitchClass pc) => pc switch
    {
        PitchClass.C => "C", PitchClass.CSharp => "Cis", PitchClass.D => "D", PitchClass.DSharp => "Dis",
        PitchClass.E => "E", PitchClass.F => "F", PitchClass.FSharp => "Fis", PitchClass.G => "G",
        PitchClass.GSharp => "Gis", PitchClass.A => "A", PitchClass.ASharp => "B", PitchClass.B => "H",
        _ => "?"
    };

    public static string GetFlatName(this PitchClass pc) => pc switch
    {
        PitchClass.C => "C", PitchClass.CSharp => "Db", PitchClass.D => "D", PitchClass.DSharp => "Eb",
        PitchClass.E => "E", PitchClass.F => "F", PitchClass.FSharp => "Gb", PitchClass.G => "G",
        PitchClass.GSharp => "Ab", PitchClass.A => "A", PitchClass.ASharp => "Bb", PitchClass.B => "B",
        _ => "?"
    };

    public static PitchClass Transposed(this PitchClass pc, int semitones) =>
        (PitchClass)((((int)pc + semitones) % 12 + 12) % 12);

    public static PitchClass FromMidiNote(int midiNote) =>
        (PitchClass)(((midiNote % 12) + 12) % 12);
}

// MARK: - ScaleType

public sealed record ScaleType(string Name, IReadOnlyList<int> Intervals)
{
    public static ScaleType Major { get; } = new("Major", [0, 2, 4, 5, 7, 9, 11]);
    public static ScaleType NaturalMinor { get; } = new("Natural Minor", [0, 2, 3, 5, 7, 8, 10]);
    public static ScaleType HarmonicMinor { get; } = new("Harmonic Minor", [0, 2, 3, 5, 7, 8, 11]);
}

// MARK: - Scale

public sealed record Scale(PitchClass Root, ScaleType ScaleType)
{
    public IReadOnlyList<PitchClass> PitchClasses =>
        ScaleType.Intervals.Select(i => Root.Transposed(i)).ToArray();

    public bool Contains(PitchClass pc) => PitchClasses.Contains(pc);

    /// <summary>Returns the 1-based scale degree (1-7), or null if not in scale.</summary>
    public int? Degree(PitchClass pc)
    {
        var pcs = PitchClasses;
        for (var i = 0; i < pcs.Count; i++)
        {
            if (pcs[i] == pc) return i + 1;
        }
        return null;
    }
}

// MARK: - ChordQuality

public enum ChordQuality
{
    Major, Minor, Diminished, Augmented, Dominant7, Major7, Minor7, Diminished7
}

public static class ChordQualityExtensions
{
    public static string GetSymbol(this ChordQuality q) => q switch
    {
        ChordQuality.Major => "",
        ChordQuality.Minor => "m",
        ChordQuality.Diminished => "\u00B0",
        ChordQuality.Augmented => "+",
        ChordQuality.Dominant7 => "7",
        ChordQuality.Major7 => "maj7",
        ChordQuality.Minor7 => "m7",
        ChordQuality.Diminished7 => "\u00B07",
        _ => ""
    };

    public static string GetGermanName(this ChordQuality q) => q switch
    {
        ChordQuality.Major => "Dur",
        ChordQuality.Minor => "Moll",
        ChordQuality.Diminished => "Vermindert",
        ChordQuality.Augmented => "\u00DCberm\u00E4\u00DFig",
        ChordQuality.Dominant7 => "Dominant-7",
        ChordQuality.Major7 => "Major-7",
        ChordQuality.Minor7 => "Moll-7",
        ChordQuality.Diminished7 => "Verm.-7",
        _ => ""
    };
}

// MARK: - ChordType

public sealed record ChordType(ChordQuality Quality, IReadOnlyList<int> Intervals)
{
    public static ChordType Major { get; } = new(ChordQuality.Major, [0, 4, 7]);
    public static ChordType Minor { get; } = new(ChordQuality.Minor, [0, 3, 7]);
    public static ChordType Diminished { get; } = new(ChordQuality.Diminished, [0, 3, 6]);
    public static ChordType Augmented { get; } = new(ChordQuality.Augmented, [0, 4, 8]);
    public static ChordType Dominant7 { get; } = new(ChordQuality.Dominant7, [0, 4, 7, 10]);
    public static ChordType Major7 { get; } = new(ChordQuality.Major7, [0, 4, 7, 11]);
    public static ChordType Minor7 { get; } = new(ChordQuality.Minor7, [0, 3, 7, 10]);
    public static ChordType Diminished7 { get; } = new(ChordQuality.Diminished7, [0, 3, 6, 9]);

    public static IReadOnlyList<ChordType> AllTypes { get; } =
        [Major, Minor, Diminished, Augmented, Dominant7, Major7, Minor7, Diminished7];
}

// MARK: - Inversion

public enum Inversion
{
    Root = 0, First, Second, Third
}

// MARK: - Chord

public sealed record Chord(PitchClass Root, ChordType ChordType, Inversion Inversion = Inversion.Root)
{
    public IReadOnlyList<PitchClass> PitchClasses =>
        ChordType.Intervals.Select(i => Root.Transposed(i)).ToArray();

    public string DisplayName => Root.GetName() + ChordType.Quality.GetSymbol();

    public string GermanDisplayName => Root.GetGermanName() + ChordType.Quality.GetSymbol();

    public IReadOnlyList<int> MidiNotes(int octave = 3)
    {
        var baseMidi = (octave + 1) * 12 + (int)Root;
        var notes = ChordType.Intervals.Select(i => baseMidi + i).ToList();

        switch (Inversion)
        {
            case Inversion.First when notes.Count >= 3:
                notes[0] += 12;
                notes.Sort();
                break;
            case Inversion.Second when notes.Count >= 3:
                notes[0] += 12;
                notes[1] += 12;
                notes.Sort();
                break;
            case Inversion.Third when notes.Count >= 4:
                notes[0] += 12;
                notes[1] += 12;
                notes[2] += 12;
                notes.Sort();
                break;
        }

        return notes;
    }
}

// MARK: - ChordDetection

public static class ChordDetection
{
    public static Chord? Detect(IReadOnlyList<int> midiNotes)
    {
        var pitchClassValues = new HashSet<int>(midiNotes.Select(n => ((n % 12) + 12) % 12));
        if (pitchClassValues.Count < 3) return null;

        var sortedPC = pitchClassValues.OrderBy(x => x).ToArray();
        var bassNote = midiNotes.Min();
        var bassPitchClass = ((bassNote % 12) + 12) % 12;

        foreach (var chordType in ChordType.AllTypes)
        {
            var expectedIntervals = new HashSet<int>(chordType.Intervals);
            foreach (var potentialRoot in sortedPC)
            {
                var actualIntervals = new HashSet<int>(sortedPC.Select(pc => ((pc - potentialRoot) + 12) % 12));
                if (!actualIntervals.SetEquals(expectedIntervals)) continue;

                var root = (PitchClass)potentialRoot;
                var inversion = DetermineInversion(potentialRoot, bassPitchClass, chordType.Intervals);
                return new Chord(root, chordType, inversion);
            }
        }

        return null;
    }

    public static IReadOnlyList<Chord> DetectAll(IReadOnlyList<int> midiNotes)
    {
        var pitchClassValues = new HashSet<int>(midiNotes.Select(n => ((n % 12) + 12) % 12));
        if (pitchClassValues.Count < 3) return [];

        var sortedPC = pitchClassValues.OrderBy(x => x).ToArray();
        var bassNote = midiNotes.Min();
        var bassPitchClass = ((bassNote % 12) + 12) % 12;
        var results = new List<Chord>();

        foreach (var chordType in ChordType.AllTypes)
        {
            var expectedIntervals = new HashSet<int>(chordType.Intervals);
            foreach (var potentialRoot in sortedPC)
            {
                var actualIntervals = new HashSet<int>(sortedPC.Select(pc => ((pc - potentialRoot) + 12) % 12));
                if (!actualIntervals.SetEquals(expectedIntervals)) continue;

                var root = (PitchClass)potentialRoot;
                var inversion = DetermineInversion(potentialRoot, bassPitchClass, chordType.Intervals);
                results.Add(new Chord(root, chordType, inversion));
            }
        }

        return results;
    }

    private static Inversion DetermineInversion(int root, int bassPC, IReadOnlyList<int> intervals)
    {
        if (bassPC == root) return Inversion.Root;
        var chordPCs = intervals.Select(i => (root + i) % 12).ToList();
        var bassIndex = chordPCs.IndexOf(bassPC);
        return bassIndex switch
        {
            1 => Inversion.First,
            2 => Inversion.Second,
            3 => Inversion.Third,
            _ => Inversion.Root
        };
    }
}

// MARK: - HarmonicFunction

public enum HarmonicFunction
{
    Tonic, Subdominant, Dominant
}

public static class HarmonicFunctionExtensions
{
    public static string GetGermanName(this HarmonicFunction f) => f switch
    {
        HarmonicFunction.Tonic => "Tonika",
        HarmonicFunction.Subdominant => "Subdominante",
        HarmonicFunction.Dominant => "Dominante",
        _ => ""
    };

    public static string GetAbbreviation(this HarmonicFunction f) => f switch
    {
        HarmonicFunction.Tonic => "T",
        HarmonicFunction.Subdominant => "S",
        HarmonicFunction.Dominant => "D",
        _ => ""
    };
}

// MARK: - DiatonicChord

public sealed record DiatonicChord(
    int Degree,
    string RomanNumeral,
    ChordType ChordType,
    PitchClass Root,
    HarmonicFunction HarmonicFunction,
    string FunctionLabel,
    string Description
);

// MARK: - DiatonicAnalysis

public static class DiatonicAnalysis
{
    public static IReadOnlyList<DiatonicChord> DiatonicChords(Scale scale)
    {
        var pcs = scale.PitchClasses;
        var isMajor = scale.ScaleType == ScaleType.Major;

        var templates = isMajor
            ? new (string roman, ChordQuality quality, HarmonicFunction function, string label, string desc)[]
            {
                ("I",    ChordQuality.Major,      HarmonicFunction.Tonic,       "T",   "Ruhepunkt"),
                ("ii",   ChordQuality.Minor,      HarmonicFunction.Subdominant, "Sp",  "Subdominant-Parallele"),
                ("iii",  ChordQuality.Minor,      HarmonicFunction.Dominant,    "Dp",  "Dominant-Parallele"),
                ("IV",   ChordQuality.Major,      HarmonicFunction.Subdominant, "S",   "Spannungsaufbau"),
                ("V",    ChordQuality.Major,      HarmonicFunction.Dominant,    "D",   "H\u00F6chste Spannung"),
                ("vi",   ChordQuality.Minor,      HarmonicFunction.Tonic,       "Tp",  "Tonika-Parallele"),
                ("vii\u00B0", ChordQuality.Diminished, HarmonicFunction.Dominant, "D\u2077", "Leittonakkord"),
            }
            : new (string roman, ChordQuality quality, HarmonicFunction function, string label, string desc)[]
            {
                ("i",    ChordQuality.Minor,      HarmonicFunction.Tonic,       "t",   "Ruhepunkt"),
                ("ii\u00B0", ChordQuality.Diminished, HarmonicFunction.Subdominant, "s\u00B0", "Subdominant-Vertreter"),
                ("III",  ChordQuality.Major,      HarmonicFunction.Tonic,       "tP",  "Tonikaparallele"),
                ("iv",   ChordQuality.Minor,      HarmonicFunction.Subdominant, "s",   "Spannungsaufbau"),
                ("v",    ChordQuality.Minor,      HarmonicFunction.Dominant,    "d",   "Moll-Dominante"),
                ("VI",   ChordQuality.Major,      HarmonicFunction.Subdominant, "sP",  "Subdominantparallele"),
                ("VII",  ChordQuality.Major,      HarmonicFunction.Dominant,    "VII", "Subtonikaakkord"),
            };

        return templates.Select((tmpl, index) =>
        {
            var chordType = tmpl.quality switch
            {
                ChordQuality.Major => ChordType.Major,
                ChordQuality.Minor => ChordType.Minor,
                ChordQuality.Diminished => ChordType.Diminished,
                ChordQuality.Augmented => ChordType.Augmented,
                _ => ChordType.Major
            };

            return new DiatonicChord(
                index + 1,
                tmpl.roman,
                chordType,
                pcs[index],
                tmpl.function,
                tmpl.label,
                tmpl.desc
            );
        }).ToArray();
    }

    public static DiatonicChord? Analyze(Chord chord, Scale scale)
    {
        var diatonic = DiatonicChords(scale);
        return diatonic.FirstOrDefault(dc => dc.Root == chord.Root && dc.ChordType.Quality == chord.ChordType.Quality);
    }

    public static DiatonicChord? AnalyzeByRoot(Chord chord, Scale scale)
    {
        var diatonic = DiatonicChords(scale);
        return diatonic.FirstOrDefault(dc => dc.Root == chord.Root);
    }
}

// MARK: - ProgressionStep

public sealed record ProgressionStep(int Degree, string Label, ChordQuality? QualityOverride = null);

// MARK: - ProgressionTemplate

public sealed record ProgressionTemplate(
    string Id,
    string Name,
    string Composer,
    string Era,
    IReadOnlyList<ProgressionStep> Steps,
    bool IsMajor = true,
    string Description = ""
)
{
    public IReadOnlyList<DiatonicChord> Resolve(Scale scale)
    {
        var diatonic = DiatonicAnalysis.DiatonicChords(scale);
        var results = new List<DiatonicChord>();
        foreach (var step in Steps)
        {
            if (step.Degree < 1 || step.Degree > diatonic.Count) continue;
            var dc = diatonic[step.Degree - 1];
            if (step.QualityOverride is { } ov)
            {
                var overriddenType = ov switch
                {
                    ChordQuality.Major => ChordType.Major,
                    ChordQuality.Minor => ChordType.Minor,
                    ChordQuality.Diminished => ChordType.Diminished,
                    ChordQuality.Augmented => ChordType.Augmented,
                    _ => dc.ChordType
                };
                results.Add(dc with { RomanNumeral = step.Label, ChordType = overriddenType });
            }
            else
            {
                results.Add(dc);
            }
        }
        return results;
    }

    // Built-in Major Progressions

    public static ProgressionTemplate Pachelbel { get; } = new(
        "pachelbel", "Pachelbel-Kanon", "Johann Pachelbel", "~1680",
        [new(1, "I"), new(5, "V"), new(6, "vi"), new(3, "iii"), new(4, "IV"), new(1, "I"), new(4, "IV"), new(5, "V")],
        true, "Der ber\u00FChmte Kanon in D-Dur"
    );

    public static ProgressionTemplate Fifties { get; } = new(
        "fifties", "50s Progression", "Pop/Doo-Wop", "1950er",
        [new(1, "I"), new(6, "vi"), new(4, "IV"), new(5, "V")],
        true, "Stand By Me, Earth Angel, etc."
    );

    public static ProgressionTemplate AxisOfAwesome { get; } = new(
        "axis", "Axis of Awesome", "Pop", "Modern",
        [new(1, "I"), new(5, "V"), new(6, "vi"), new(4, "IV")],
        true, "Let It Be, No Woman No Cry, etc."
    );

    public static ProgressionTemplate AndalusianMajor { get; } = new(
        "andalusian-major", "Andalusische Kadenz", "Flamenco", "Traditionell",
        [new(6, "vi"), new(5, "V"), new(4, "IV"), new(3, "iii")],
        true, "Typisch f\u00FCr spanische Musik"
    );

    public static ProgressionTemplate JazzTwoFiveOne { get; } = new(
        "jazz-251", "Jazz II-V-I", "Jazz", "Klassiker",
        [new(2, "ii"), new(5, "V"), new(1, "I")],
        true, "Die wichtigste Jazz-Kadenz"
    );

    public static ProgressionTemplate Blues { get; } = new(
        "blues", "12-Takt Blues", "Blues/Rock", "Klassiker",
        [new(1,"I"),new(1,"I"),new(1,"I"),new(1,"I"),new(4,"IV"),new(4,"IV"),new(1,"I"),new(1,"I"),new(5,"V"),new(4,"IV"),new(1,"I"),new(5,"V")],
        true, "12-Takt-Blues-Schema"
    );

    // Built-in Minor Progressions

    public static ProgressionTemplate MinorCadence { get; } = new(
        "minor-cadence", "Moll-Kadenz", "Klassik", "Traditionell",
        [new(1, "i"), new(4, "iv"), new(5, "v"), new(1, "i")],
        false, "Klassische Moll-Kadenz"
    );

    public static ProgressionTemplate AndalusianMinor { get; } = new(
        "andalusian-minor", "Andalusische Kadenz (Moll)", "Flamenco", "Traditionell",
        [new(1, "i"), new(7, "VII"), new(6, "VI"), new(5, "V", ChordQuality.Major)],
        false, "Hit The Road Jack, etc."
    );

    public static ProgressionTemplate MinorPop { get; } = new(
        "minor-pop", "Moll Pop", "Pop", "Modern",
        [new(1, "i"), new(6, "VI"), new(7, "VII"), new(5, "v")],
        false, "Beliebte Moll-Progression"
    );

    public static IReadOnlyList<ProgressionTemplate> AllMajor { get; } =
        [Pachelbel, Fifties, AxisOfAwesome, AndalusianMajor, JazzTwoFiveOne, Blues];

    public static IReadOnlyList<ProgressionTemplate> AllMinor { get; } =
        [MinorCadence, AndalusianMinor, MinorPop];

    public static IReadOnlyList<ProgressionTemplate> All { get; } =
        [.. AllMajor, .. AllMinor];
}

// MARK: - ExerciseMode

public enum ExerciseMode
{
    FreePlay, ChordPrompt, ProgressionGuide, ScalePractice
}

// MARK: - ExercisePrompt

public sealed record ExercisePrompt(
    string Instruction,
    HashSet<int> ExpectedPitchClasses,
    bool AcceptInversions = true,
    int? Degree = null,
    string? RomanNumeral = null
);

// MARK: - ExerciseResult

public enum ExerciseResult
{
    Correct, Incorrect, Partial, Waiting
}

// MARK: - ExerciseState

public sealed class ExerciseState
{
    public ExerciseMode Mode { get; set; } = ExerciseMode.FreePlay;
    public ExercisePrompt? CurrentPrompt { get; set; }
    public ExerciseResult Result { get; set; } = ExerciseResult.Waiting;
    public ProgressionTemplate? ProgressionTemplate { get; set; }
    public int ProgressionIndex { get; set; }
    public int TotalSteps { get; set; }
    public int CompletedCount { get; set; }
    public int Streak { get; set; }

    public ExerciseState(ExerciseMode mode = ExerciseMode.FreePlay)
    {
        Mode = mode;
    }
}

// MARK: - ExerciseEvaluation

public static class ExerciseEvaluation
{
    public static ExerciseResult Evaluate(IReadOnlySet<int> activePitchClasses, ExercisePrompt prompt)
    {
        if (prompt.ExpectedPitchClasses.Count == 0) return ExerciseResult.Waiting;
        if (activePitchClasses.Count == 0) return ExerciseResult.Waiting;

        if (prompt.AcceptInversions)
        {
            if (activePitchClasses.SetEquals(prompt.ExpectedPitchClasses)) return ExerciseResult.Correct;
            if (activePitchClasses.IsSubsetOf(prompt.ExpectedPitchClasses) && activePitchClasses.Count >= 2) return ExerciseResult.Partial;
            if (activePitchClasses.Count >= prompt.ExpectedPitchClasses.Count) return ExerciseResult.Incorrect;
            return ExerciseResult.Waiting;
        }
        else
        {
            if (activePitchClasses.SetEquals(prompt.ExpectedPitchClasses)) return ExerciseResult.Correct;
            if (activePitchClasses.IsSubsetOf(prompt.ExpectedPitchClasses)) return ExerciseResult.Partial;
            return ExerciseResult.Incorrect;
        }
    }
}

// MARK: - HarmonyTrainerState

public sealed class HarmonyTrainerState
{
    public bool IsEnabled { get; set; }
    public PitchClass SelectedKey { get; set; } = PitchClass.C;
    public ScaleType SelectedScaleType { get; set; } = ScaleType.Major;
    public Chord? DetectedChord { get; set; }
    public DiatonicChord? DiatonicAnalysisResult { get; set; }
    public IReadOnlyList<DiatonicChord> DiatonicChordsList { get; set; } = [];
    public ExerciseState Exercise { get; set; } = new();
    public HashSet<int> ActivePitchClasses { get; set; } = [];
}

// MARK: - HarmonyTrainerSettings

public sealed record HarmonyTrainerSettings(
    bool IsEnabled = false,
    PitchClass SelectedKey = PitchClass.C,
    ScaleType? SelectedScaleType = null,
    ExerciseMode DefaultExerciseMode = ExerciseMode.FreePlay,
    bool AcceptInversions = true
)
{
    public ScaleType ResolvedScaleType => SelectedScaleType ?? ScaleType.Major;
}

// MARK: - HarmonyTrainerEngine

public sealed class HarmonyTrainerEngine
{
    private readonly Dictionary<int, int> _activeNotes = [];
    private bool _acceptInversions;

    public HarmonyTrainerState State { get; } = new();

    public HarmonyTrainerEngine(HarmonyTrainerSettings? settings = null)
    {
        var s = settings ?? new HarmonyTrainerSettings();
        _acceptInversions = s.AcceptInversions;
        State.IsEnabled = s.IsEnabled;
        State.SelectedKey = s.SelectedKey;
        State.SelectedScaleType = s.ResolvedScaleType;
        RebuildDiatonicChords();
    }

    // Configuration

    public void SetEnabled(bool enabled)
    {
        State.IsEnabled = enabled;
        if (!enabled) Reset();
    }

    public void SetKey(PitchClass key)
    {
        State.SelectedKey = key;
        RebuildDiatonicChords();
        ResetExercise();
    }

    public void SetScaleType(ScaleType scaleType)
    {
        State.SelectedScaleType = scaleType;
        RebuildDiatonicChords();
        ResetExercise();
    }

    public void SetAcceptInversions(bool accept) => _acceptInversions = accept;

    // MIDI Consumption

    public void Consume(MidiEvent midiEvent)
    {
        if (!State.IsEnabled) return;

        if (midiEvent.IsNoteOn && midiEvent.Velocity > 0)
            _activeNotes[midiEvent.Note] = midiEvent.Velocity;
        else
            _activeNotes.Remove(midiEvent.Note);

        var midiNotes = _activeNotes.Keys.ToArray();
        State.ActivePitchClasses = new HashSet<int>(midiNotes.Select(n => ((n % 12) + 12) % 12));

        State.DetectedChord = ChordDetection.Detect(midiNotes);

        var scale = new Scale(State.SelectedKey, State.SelectedScaleType);
        State.DiatonicAnalysisResult = State.DetectedChord is { } dc
            ? DiatonicAnalysis.Analyze(dc, scale)
            : null;

        EvaluateExercise();
    }

    // Exercise Control

    public void StartExercise(ExerciseMode mode, ProgressionTemplate? progression = null)
    {
        State.Exercise = new ExerciseState(mode);

        switch (mode)
        {
            case ExerciseMode.FreePlay:
                break;
            case ExerciseMode.ChordPrompt:
                State.Exercise.CurrentPrompt = GenerateRandomChordPrompt();
                break;
            case ExerciseMode.ProgressionGuide when progression is not null:
                State.Exercise.ProgressionTemplate = progression;
                State.Exercise.TotalSteps = progression.Steps.Count;
                State.Exercise.ProgressionIndex = 0;
                State.Exercise.CurrentPrompt = GenerateProgressionPrompt(0, progression);
                break;
            case ExerciseMode.ScalePractice:
                State.Exercise.CurrentPrompt = GenerateScalePrompt(1);
                State.Exercise.TotalSteps = 7;
                State.Exercise.ProgressionIndex = 0;
                break;
        }
    }

    public void AdvanceExercise()
    {
        switch (State.Exercise.Mode)
        {
            case ExerciseMode.FreePlay:
                break;
            case ExerciseMode.ChordPrompt:
                State.Exercise.Result = ExerciseResult.Waiting;
                State.Exercise.CurrentPrompt = GenerateRandomChordPrompt();
                break;
            case ExerciseMode.ProgressionGuide:
            {
                var nextIndex = State.Exercise.ProgressionIndex + 1;
                if (State.Exercise.ProgressionTemplate is { } prog && nextIndex < prog.Steps.Count)
                {
                    State.Exercise.ProgressionIndex = nextIndex;
                    State.Exercise.Result = ExerciseResult.Waiting;
                    State.Exercise.CurrentPrompt = GenerateProgressionPrompt(nextIndex, prog);
                }
                else
                {
                    State.Exercise.Result = ExerciseResult.Correct;
                    State.Exercise.CurrentPrompt = null;
                }
                break;
            }
            case ExerciseMode.ScalePractice:
            {
                var nextDegree = State.Exercise.ProgressionIndex + 2;
                if (nextDegree <= 7)
                {
                    State.Exercise.ProgressionIndex++;
                    State.Exercise.Result = ExerciseResult.Waiting;
                    State.Exercise.CurrentPrompt = GenerateScalePrompt(nextDegree);
                }
                else
                {
                    State.Exercise.Result = ExerciseResult.Correct;
                    State.Exercise.CurrentPrompt = null;
                }
                break;
            }
        }
    }

    public void ResetExercise()
    {
        var mode = State.Exercise.Mode;
        var prog = State.Exercise.ProgressionTemplate;
        StartExercise(mode, prog);
    }

    public void Reset()
    {
        _activeNotes.Clear();
        State.ActivePitchClasses = [];
        State.DetectedChord = null;
        State.DiatonicAnalysisResult = null;
        State.Exercise = new ExerciseState();
    }

    // Private

    private void RebuildDiatonicChords()
    {
        var scale = new Scale(State.SelectedKey, State.SelectedScaleType);
        State.DiatonicChordsList = DiatonicAnalysis.DiatonicChords(scale);
    }

    private void EvaluateExercise()
    {
        if (State.Exercise.CurrentPrompt is not { } prompt) return;

        var previousResult = State.Exercise.Result;
        var result = ExerciseEvaluation.Evaluate(State.ActivePitchClasses, prompt);
        State.Exercise.Result = result;

        if (result == ExerciseResult.Correct && previousResult != ExerciseResult.Correct)
        {
            State.Exercise.CompletedCount++;
            State.Exercise.Streak++;
        }
        else if (result == ExerciseResult.Incorrect)
        {
            State.Exercise.Streak = 0;
        }
    }

    private ExercisePrompt GenerateRandomChordPrompt()
    {
        var diatonic = State.DiatonicChordsList;
        if (diatonic.Count == 0)
            return new ExercisePrompt("Keine Akkorde verf\u00FCgbar", []);

        var randomIndex = Random.Shared.Next(diatonic.Count);
        var dc = diatonic[randomIndex];
        var chord = new Chord(dc.Root, dc.ChordType);
        var expectedPC = new HashSet<int>(chord.PitchClasses.Select(pc => (int)pc));
        var scaleName = State.SelectedScaleType == ScaleType.Major ? "Dur" : "Moll";

        return new ExercisePrompt(
            $"Spiele {dc.RomanNumeral} in {State.SelectedKey.GetGermanName()}-{scaleName}",
            expectedPC,
            _acceptInversions,
            dc.Degree,
            dc.RomanNumeral
        );
    }

    private ExercisePrompt GenerateProgressionPrompt(int index, ProgressionTemplate template)
    {
        var scale = new Scale(State.SelectedKey, State.SelectedScaleType);
        var resolved = template.Resolve(scale);
        if (index >= resolved.Count)
            return new ExercisePrompt("Progression abgeschlossen!", []);

        var dc = resolved[index];
        var chord = new Chord(dc.Root, dc.ChordType);
        var expectedPC = new HashSet<int>(chord.PitchClasses.Select(pc => (int)pc));

        return new ExercisePrompt(
            $"Schritt {index + 1}/{resolved.Count}: {dc.RomanNumeral} ({dc.Root.GetGermanName()}{dc.ChordType.Quality.GetSymbol()})",
            expectedPC,
            _acceptInversions,
            dc.Degree,
            dc.RomanNumeral
        );
    }

    private ExercisePrompt GenerateScalePrompt(int degree)
    {
        var scale = new Scale(State.SelectedKey, State.SelectedScaleType);
        var pcs = scale.PitchClasses;
        if (degree < 1 || degree > pcs.Count)
            return new ExercisePrompt("Tonleiter abgeschlossen!", []);

        var pc = pcs[degree - 1];
        var scaleName = State.SelectedScaleType == ScaleType.Major ? "Dur" : "Moll";

        return new ExercisePrompt(
            $"Spiele Stufe {degree} der {State.SelectedKey.GetGermanName()}-{scaleName}-Tonleiter ({pc.GetGermanName()})",
            [(int)pc],
            false,
            degree,
            $"{degree}"
        );
    }
}
