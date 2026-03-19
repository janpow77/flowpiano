using FlowPiano.Windows.Core;
using Xunit;

namespace FlowPiano.Windows.Tests;

public sealed class HarmonyTrainerTests
{
    // MARK: - Scale Construction

    [Fact]
    public void MajorScaleConstruction()
    {
        var scale = new Scale(PitchClass.C, ScaleType.Major);
        Assert.Equal([PitchClass.C, PitchClass.D, PitchClass.E, PitchClass.F, PitchClass.G, PitchClass.A, PitchClass.B], scale.PitchClasses);
    }

    [Fact]
    public void MinorScaleConstruction()
    {
        var scale = new Scale(PitchClass.A, ScaleType.NaturalMinor);
        Assert.Equal([PitchClass.A, PitchClass.B, PitchClass.C, PitchClass.D, PitchClass.E, PitchClass.F, PitchClass.G], scale.PitchClasses);
    }

    [Fact]
    public void ScaleContainsPitchClass()
    {
        var scale = new Scale(PitchClass.C, ScaleType.Major);
        Assert.True(scale.Contains(PitchClass.C));
        Assert.True(scale.Contains(PitchClass.E));
        Assert.False(scale.Contains(PitchClass.CSharp));
        Assert.False(scale.Contains(PitchClass.FSharp));
    }

    [Fact]
    public void ScaleDegree()
    {
        var scale = new Scale(PitchClass.C, ScaleType.Major);
        Assert.Equal(1, scale.Degree(PitchClass.C));
        Assert.Equal(2, scale.Degree(PitchClass.D));
        Assert.Equal(5, scale.Degree(PitchClass.G));
        Assert.Equal(7, scale.Degree(PitchClass.B));
        Assert.Null(scale.Degree(PitchClass.FSharp));
    }

    // MARK: - Diatonic Chords

    [Fact]
    public void DiatonicChordsInCMajor()
    {
        var scale = new Scale(PitchClass.C, ScaleType.Major);
        var chords = DiatonicAnalysis.DiatonicChords(scale);

        Assert.Equal(7, chords.Count);

        Assert.Equal(PitchClass.C, chords[0].Root);
        Assert.Equal(ChordQuality.Major, chords[0].ChordType.Quality);
        Assert.Equal("I", chords[0].RomanNumeral);

        Assert.Equal(PitchClass.D, chords[1].Root);
        Assert.Equal(ChordQuality.Minor, chords[1].ChordType.Quality);
        Assert.Equal("ii", chords[1].RomanNumeral);

        Assert.Equal(PitchClass.E, chords[2].Root);
        Assert.Equal(ChordQuality.Minor, chords[2].ChordType.Quality);

        Assert.Equal(PitchClass.F, chords[3].Root);
        Assert.Equal(ChordQuality.Major, chords[3].ChordType.Quality);
        Assert.Equal("IV", chords[3].RomanNumeral);

        Assert.Equal(PitchClass.G, chords[4].Root);
        Assert.Equal(ChordQuality.Major, chords[4].ChordType.Quality);
        Assert.Equal("V", chords[4].RomanNumeral);

        Assert.Equal(PitchClass.A, chords[5].Root);
        Assert.Equal(ChordQuality.Minor, chords[5].ChordType.Quality);
        Assert.Equal("vi", chords[5].RomanNumeral);

        Assert.Equal(PitchClass.B, chords[6].Root);
        Assert.Equal(ChordQuality.Diminished, chords[6].ChordType.Quality);
    }

    [Fact]
    public void DiatonicChordsInAMinor()
    {
        var scale = new Scale(PitchClass.A, ScaleType.NaturalMinor);
        var chords = DiatonicAnalysis.DiatonicChords(scale);

        Assert.Equal(7, chords.Count);
        Assert.Equal(PitchClass.A, chords[0].Root);
        Assert.Equal(ChordQuality.Minor, chords[0].ChordType.Quality);
        Assert.Equal("i", chords[0].RomanNumeral);

        Assert.Equal(PitchClass.C, chords[2].Root);
        Assert.Equal(ChordQuality.Major, chords[2].ChordType.Quality);
        Assert.Equal("III", chords[2].RomanNumeral);
    }

    [Fact]
    public void FunctionLabelsForMajorKey()
    {
        var scale = new Scale(PitchClass.C, ScaleType.Major);
        var chords = DiatonicAnalysis.DiatonicChords(scale);

        Assert.Equal("T", chords[0].FunctionLabel);
        Assert.Equal("Sp", chords[1].FunctionLabel);
        Assert.Equal("Dp", chords[2].FunctionLabel);
        Assert.Equal("S", chords[3].FunctionLabel);
        Assert.Equal("D", chords[4].FunctionLabel);
        Assert.Equal("Tp", chords[5].FunctionLabel);
    }

    // MARK: - Chord Detection

    [Fact]
    public void DetectCMajorTriad()
    {
        var chord = ChordDetection.Detect([60, 64, 67]);
        Assert.NotNull(chord);
        Assert.Equal(PitchClass.C, chord.Root);
        Assert.Equal(ChordQuality.Major, chord.ChordType.Quality);
        Assert.Equal(Inversion.Root, chord.Inversion);
    }

    [Fact]
    public void DetectCMajorFirstInversion()
    {
        var chord = ChordDetection.Detect([64, 67, 72]);
        Assert.NotNull(chord);
        Assert.Equal(PitchClass.C, chord.Root);
        Assert.Equal(ChordQuality.Major, chord.ChordType.Quality);
        Assert.Equal(Inversion.First, chord.Inversion);
    }

    [Fact]
    public void DetectAMinorTriad()
    {
        var chord = ChordDetection.Detect([57, 60, 64]);
        Assert.NotNull(chord);
        Assert.Equal(PitchClass.A, chord.Root);
        Assert.Equal(ChordQuality.Minor, chord.ChordType.Quality);
    }

    [Fact]
    public void DetectG7()
    {
        var chord = ChordDetection.Detect([55, 59, 62, 65]);
        Assert.NotNull(chord);
        Assert.Equal(PitchClass.G, chord.Root);
        Assert.Equal(ChordQuality.Dominant7, chord.ChordType.Quality);
    }

    [Fact]
    public void DetectBDiminished()
    {
        var chord = ChordDetection.Detect([59, 62, 65]);
        Assert.NotNull(chord);
        Assert.Equal(PitchClass.B, chord.Root);
        Assert.Equal(ChordQuality.Diminished, chord.ChordType.Quality);
    }

    [Fact]
    public void NoChordFromTwoNotes()
    {
        var chord = ChordDetection.Detect([60, 64]);
        Assert.Null(chord);
    }

    [Fact]
    public void NoChordFromEmptyNotes()
    {
        var chord = ChordDetection.Detect([]);
        Assert.Null(chord);
    }

    [Fact]
    public void DetectCMajorAcrossOctaves()
    {
        var chord = ChordDetection.Detect([48, 64, 79]);
        Assert.NotNull(chord);
        Assert.Equal(PitchClass.C, chord.Root);
        Assert.Equal(ChordQuality.Major, chord.ChordType.Quality);
    }

    // MARK: - Functional Analysis

    [Fact]
    public void AnalyzeChordInKey()
    {
        var scale = new Scale(PitchClass.C, ScaleType.Major);
        var chord = new Chord(PitchClass.F, ChordType.Major);
        var analysis = DiatonicAnalysis.Analyze(chord, scale);

        Assert.NotNull(analysis);
        Assert.Equal(4, analysis.Degree);
        Assert.Equal("IV", analysis.RomanNumeral);
        Assert.Equal(HarmonicFunction.Subdominant, analysis.HarmonicFunction);
    }

    [Fact]
    public void AnalyzeNonDiatonicChordReturnsNull()
    {
        var scale = new Scale(PitchClass.C, ScaleType.Major);
        var chord = new Chord(PitchClass.FSharp, ChordType.Major);
        var analysis = DiatonicAnalysis.Analyze(chord, scale);

        Assert.Null(analysis);
    }

    // MARK: - Progressions

    [Fact]
    public void PachelbelProgressionHas8Steps()
    {
        Assert.Equal(8, ProgressionTemplate.Pachelbel.Steps.Count);
        Assert.Equal(1, ProgressionTemplate.Pachelbel.Steps[0].Degree);
        Assert.Equal(5, ProgressionTemplate.Pachelbel.Steps[1].Degree);
        Assert.Equal(6, ProgressionTemplate.Pachelbel.Steps[2].Degree);
        Assert.Equal(3, ProgressionTemplate.Pachelbel.Steps[3].Degree);
    }

    [Fact]
    public void ProgressionResolveInCMajor()
    {
        var scale = new Scale(PitchClass.C, ScaleType.Major);
        var resolved = ProgressionTemplate.Pachelbel.Resolve(scale);

        Assert.Equal(8, resolved.Count);
        Assert.Equal(PitchClass.C, resolved[0].Root);
        Assert.Equal(PitchClass.G, resolved[1].Root);
        Assert.Equal(PitchClass.A, resolved[2].Root);
        Assert.Equal(PitchClass.E, resolved[3].Root);
        Assert.Equal(PitchClass.F, resolved[4].Root);
    }

    [Fact]
    public void AndalusianMinorWithMajorVOverride()
    {
        var scale = new Scale(PitchClass.A, ScaleType.NaturalMinor);
        var resolved = ProgressionTemplate.AndalusianMinor.Resolve(scale);

        Assert.Equal(4, resolved.Count);
        Assert.Equal(PitchClass.E, resolved[3].Root);
        Assert.Equal(ChordQuality.Major, resolved[3].ChordType.Quality);
    }

    // MARK: - Exercise Evaluation

    [Fact]
    public void ChordPromptCorrect()
    {
        var prompt = new ExercisePrompt("Play IV in C major", [5, 9, 0], true, 4, "IV");
        var result = ExerciseEvaluation.Evaluate(new HashSet<int>([5, 9, 0]), prompt);
        Assert.Equal(ExerciseResult.Correct, result);
    }

    [Fact]
    public void ChordPromptIncorrect()
    {
        var prompt = new ExercisePrompt("Play IV in C major", [5, 9, 0], true);
        var result = ExerciseEvaluation.Evaluate(new HashSet<int>([7, 11, 2]), prompt);
        Assert.Equal(ExerciseResult.Incorrect, result);
    }

    [Fact]
    public void ChordPromptPartial()
    {
        var prompt = new ExercisePrompt("Play IV in C major", [5, 9, 0], true);
        var result = ExerciseEvaluation.Evaluate(new HashSet<int>([5, 9]), prompt);
        Assert.Equal(ExerciseResult.Partial, result);
    }

    [Fact]
    public void ChordPromptWaiting()
    {
        var prompt = new ExercisePrompt("Play IV in C major", [5, 9, 0], true);
        var result = ExerciseEvaluation.Evaluate(new HashSet<int>(), prompt);
        Assert.Equal(ExerciseResult.Waiting, result);
    }

    // MARK: - Engine (with MidiEvent)

    [Fact]
    public void ConsumeBuildsChordDetection()
    {
        var trainer = new HarmonyTrainerEngine(new HarmonyTrainerSettings(IsEnabled: true));

        trainer.Consume(new MidiEvent(60, 80, true));
        trainer.Consume(new MidiEvent(64, 80, true));
        trainer.Consume(new MidiEvent(67, 80, true));

        Assert.NotNull(trainer.State.DetectedChord);
        Assert.Equal(PitchClass.C, trainer.State.DetectedChord.Root);
        Assert.Equal(ChordQuality.Major, trainer.State.DetectedChord.ChordType.Quality);
    }

    [Fact]
    public void NoteOffUpdatesDetection()
    {
        var trainer = new HarmonyTrainerEngine(new HarmonyTrainerSettings(IsEnabled: true));

        trainer.Consume(new MidiEvent(60, 80, true));
        trainer.Consume(new MidiEvent(64, 80, true));
        trainer.Consume(new MidiEvent(67, 80, true));
        Assert.NotNull(trainer.State.DetectedChord);

        trainer.Consume(new MidiEvent(60, 0, false));
        trainer.Consume(new MidiEvent(64, 0, false));
        trainer.Consume(new MidiEvent(67, 0, false));

        Assert.Null(trainer.State.DetectedChord);
        Assert.Empty(trainer.State.ActivePitchClasses);
    }

    [Fact]
    public void DiatonicAnalysisPopulatedForCMajorChord()
    {
        var trainer = new HarmonyTrainerEngine(new HarmonyTrainerSettings(
            IsEnabled: true, SelectedKey: PitchClass.C, SelectedScaleType: ScaleType.Major));

        trainer.Consume(new MidiEvent(60, 80, true));
        trainer.Consume(new MidiEvent(64, 80, true));
        trainer.Consume(new MidiEvent(67, 80, true));

        Assert.NotNull(trainer.State.DiatonicAnalysisResult);
        Assert.Equal("I", trainer.State.DiatonicAnalysisResult.RomanNumeral);
        Assert.Equal(HarmonicFunction.Tonic, trainer.State.DiatonicAnalysisResult.HarmonicFunction);
    }

    [Fact]
    public void DisabledTrainerIgnoresEvents()
    {
        var trainer = new HarmonyTrainerEngine(new HarmonyTrainerSettings(IsEnabled: false));

        trainer.Consume(new MidiEvent(60, 80, true));
        trainer.Consume(new MidiEvent(64, 80, true));
        trainer.Consume(new MidiEvent(67, 80, true));

        Assert.Null(trainer.State.DetectedChord);
        Assert.Empty(trainer.State.ActivePitchClasses);
    }

    [Fact]
    public void KeyChangeRebuildsAnalysis()
    {
        var trainer = new HarmonyTrainerEngine(new HarmonyTrainerSettings(
            IsEnabled: true, SelectedKey: PitchClass.C));

        Assert.Equal(PitchClass.C, trainer.State.DiatonicChordsList[0].Root);

        trainer.SetKey(PitchClass.G);
        Assert.Equal(PitchClass.G, trainer.State.DiatonicChordsList[0].Root);
        Assert.Equal(PitchClass.D, trainer.State.DiatonicChordsList[4].Root);
    }

    [Fact]
    public void ResetClearsAllState()
    {
        var trainer = new HarmonyTrainerEngine(new HarmonyTrainerSettings(IsEnabled: true));

        trainer.Consume(new MidiEvent(60, 80, true));
        trainer.Consume(new MidiEvent(64, 80, true));
        trainer.Consume(new MidiEvent(67, 80, true));

        trainer.Reset();

        Assert.Null(trainer.State.DetectedChord);
        Assert.Null(trainer.State.DiatonicAnalysisResult);
        Assert.Empty(trainer.State.ActivePitchClasses);
    }

    [Fact]
    public void ProgressionExerciseGeneratesPrompts()
    {
        var trainer = new HarmonyTrainerEngine(new HarmonyTrainerSettings(
            IsEnabled: true, SelectedKey: PitchClass.C, SelectedScaleType: ScaleType.Major));

        trainer.StartExercise(ExerciseMode.ProgressionGuide, ProgressionTemplate.Pachelbel);

        Assert.Equal(ExerciseMode.ProgressionGuide, trainer.State.Exercise.Mode);
        Assert.Equal(8, trainer.State.Exercise.TotalSteps);
        Assert.Equal(0, trainer.State.Exercise.ProgressionIndex);
        Assert.NotNull(trainer.State.Exercise.CurrentPrompt);
        Assert.Equal(new HashSet<int>([0, 4, 7]), trainer.State.Exercise.CurrentPrompt.ExpectedPitchClasses);
    }

    [Fact]
    public void ChordPromptExerciseEvaluatesCorrectly()
    {
        var trainer = new HarmonyTrainerEngine(new HarmonyTrainerSettings(
            IsEnabled: true, SelectedKey: PitchClass.C, SelectedScaleType: ScaleType.Major));

        trainer.StartExercise(ExerciseMode.ProgressionGuide, ProgressionTemplate.Pachelbel);

        trainer.Consume(new MidiEvent(60, 80, true));
        trainer.Consume(new MidiEvent(64, 80, true));
        trainer.Consume(new MidiEvent(67, 80, true));

        Assert.Equal(ExerciseResult.Correct, trainer.State.Exercise.Result);
        Assert.Equal(1, trainer.State.Exercise.CompletedCount);
        Assert.Equal(1, trainer.State.Exercise.Streak);
    }

    // MARK: - Display Tests

    [Fact]
    public void ChordDisplayName()
    {
        var cMajor = new Chord(PitchClass.C, ChordType.Major);
        Assert.Equal("C", cMajor.DisplayName);

        var aMinor = new Chord(PitchClass.A, ChordType.Minor);
        Assert.Equal("Am", aMinor.DisplayName);

        var g7 = new Chord(PitchClass.G, ChordType.Dominant7);
        Assert.Equal("G7", g7.DisplayName);

        var bDim = new Chord(PitchClass.B, ChordType.Diminished);
        Assert.Equal("B\u00B0", bDim.DisplayName);
    }

    [Fact]
    public void PitchClassFromMidiNote()
    {
        Assert.Equal(PitchClass.C, PitchClassExtensions.FromMidiNote(60));
        Assert.Equal(PitchClass.A, PitchClassExtensions.FromMidiNote(69));
        Assert.Equal(PitchClass.C, PitchClassExtensions.FromMidiNote(72));
        Assert.Equal(PitchClass.CSharp, PitchClassExtensions.FromMidiNote(61));
    }

    [Fact]
    public void ChordMidiNotes()
    {
        var cMajor = new Chord(PitchClass.C, ChordType.Major);
        var notes = cMajor.MidiNotes(3);
        Assert.Equal([48, 52, 55], notes);

        var cMajorFirst = new Chord(PitchClass.C, ChordType.Major, Inversion.First);
        var firstNotes = cMajorFirst.MidiNotes(3);
        Assert.Equal([52, 55, 60], firstNotes);
    }

    // MARK: - Coordinator Integration

    [Fact]
    public void CoordinatorHarmonyTrainerIntegration()
    {
        var coordinator = new FlowPianoSessionCoordinator();
        coordinator.InstallPreviewHardwareProfile();
        coordinator.StartSession();

        coordinator.SetHarmonyTrainerEnabled(true);
        Assert.True(coordinator.Snapshot.HarmonyTrainer.IsEnabled);

        coordinator.SetHarmonyTrainerKey(PitchClass.G);
        Assert.Equal(PitchClass.G, coordinator.Snapshot.HarmonyTrainer.SelectedKey);
        Assert.Equal(PitchClass.G, coordinator.Snapshot.HarmonyTrainer.DiatonicChordsList[0].Root);
    }
}
