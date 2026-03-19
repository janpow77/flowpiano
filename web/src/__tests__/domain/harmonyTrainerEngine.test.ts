import { describe, it, expect } from 'vitest';
import { PitchClass } from '../../domain/pitchClass.js';
import { MAJOR } from '../../domain/scaleType.js';
import { ChordQuality } from '../../domain/chordQuality.js';
import { HarmonicFunction } from '../../domain/harmonicFunction.js';
import { Inversion } from '../../domain/inversion.js';
import { ExerciseMode, ExerciseResult } from '../../domain/exercise.js';
import { HarmonyTrainerEngine } from '../../domain/harmonyTrainerEngine.js';
import { PACHELBEL } from '../../domain/progressionTemplate.js';
import { chordDisplayName, chordMidiNotes, createChord } from '../../domain/chord.js';
import { CHORD_MAJOR, CHORD_MINOR, CHORD_DOMINANT7, CHORD_DIMINISHED } from '../../domain/chordType.js';
import { pitchClassFromMidiNote } from '../../domain/pitchClass.js';

describe('HarmonyTrainerEngine', () => {
  it('consumes MIDI and detects chord', () => {
    const engine = new HarmonyTrainerEngine(true);

    engine.consume(60, 80, true); // C4
    engine.consume(64, 80, true); // E4
    engine.consume(67, 80, true); // G4

    expect(engine.state.detectedChord).not.toBeNull();
    expect(engine.state.detectedChord!.root).toBe(PitchClass.C);
    expect(engine.state.detectedChord!.chordType.quality).toBe(ChordQuality.Major);
  });

  it('note off updates detection', () => {
    const engine = new HarmonyTrainerEngine(true);

    engine.consume(60, 80, true);
    engine.consume(64, 80, true);
    engine.consume(67, 80, true);
    expect(engine.state.detectedChord).not.toBeNull();

    engine.consume(60, 0, false);
    engine.consume(64, 0, false);
    engine.consume(67, 0, false);

    expect(engine.state.detectedChord).toBeNull();
    expect(engine.state.activePitchClasses.size).toBe(0);
  });

  it('populates diatonic analysis for C major chord', () => {
    const engine = new HarmonyTrainerEngine(true, PitchClass.C, MAJOR);

    engine.consume(60, 80, true);
    engine.consume(64, 80, true);
    engine.consume(67, 80, true);

    expect(engine.state.diatonicAnalysis).not.toBeNull();
    expect(engine.state.diatonicAnalysis!.romanNumeral).toBe('I');
    expect(engine.state.diatonicAnalysis!.harmonicFunction).toBe(HarmonicFunction.Tonic);
  });

  it('disabled trainer ignores events', () => {
    const engine = new HarmonyTrainerEngine(false);

    engine.consume(60, 80, true);
    engine.consume(64, 80, true);
    engine.consume(67, 80, true);

    expect(engine.state.detectedChord).toBeNull();
    expect(engine.state.activePitchClasses.size).toBe(0);
  });

  it('key change rebuilds diatonic chords', () => {
    const engine = new HarmonyTrainerEngine(true, PitchClass.C);

    expect(engine.state.diatonicChords[0].root).toBe(PitchClass.C);

    engine.setKey(PitchClass.G);
    expect(engine.state.diatonicChords[0].root).toBe(PitchClass.G);
    expect(engine.state.diatonicChords[4].root).toBe(PitchClass.D); // V in G major = D
  });

  it('reset clears all state', () => {
    const engine = new HarmonyTrainerEngine(true);

    engine.consume(60, 80, true);
    engine.consume(64, 80, true);
    engine.consume(67, 80, true);

    engine.reset();

    expect(engine.state.detectedChord).toBeNull();
    expect(engine.state.diatonicAnalysis).toBeNull();
    expect(engine.state.activePitchClasses.size).toBe(0);
  });

  it('progression exercise generates prompts', () => {
    const engine = new HarmonyTrainerEngine(true, PitchClass.C, MAJOR);

    engine.startExercise(ExerciseMode.ProgressionGuide, PACHELBEL);

    expect(engine.state.exercise.mode).toBe(ExerciseMode.ProgressionGuide);
    expect(engine.state.exercise.totalSteps).toBe(8);
    expect(engine.state.exercise.progressionIndex).toBe(0);
    expect(engine.state.exercise.currentPrompt).not.toBeNull();
    // First step is I (C major), expected pitch classes: C=0, E=4, G=7
    expect(engine.state.exercise.currentPrompt!.expectedPitchClasses).toEqual(new Set([0, 4, 7]));
  });

  it('evaluates progression exercise correctly', () => {
    const engine = new HarmonyTrainerEngine(true, PitchClass.C, MAJOR);

    engine.startExercise(ExerciseMode.ProgressionGuide, PACHELBEL);

    // Play C major (I)
    engine.consume(60, 80, true);
    engine.consume(64, 80, true);
    engine.consume(67, 80, true);

    expect(engine.state.exercise.result).toBe(ExerciseResult.Correct);
    expect(engine.state.exercise.completedCount).toBe(1);
    expect(engine.state.exercise.streak).toBe(1);
  });
});

describe('Chord helpers', () => {
  it('chord display name', () => {
    expect(chordDisplayName(createChord(PitchClass.C, CHORD_MAJOR))).toBe('C');
    expect(chordDisplayName(createChord(PitchClass.A, CHORD_MINOR))).toBe('Am');
    expect(chordDisplayName(createChord(PitchClass.G, CHORD_DOMINANT7))).toBe('G7');
    expect(chordDisplayName(createChord(PitchClass.B, CHORD_DIMINISHED))).toBe('B\u00B0');
  });

  it('pitch class from MIDI note', () => {
    expect(pitchClassFromMidiNote(60)).toBe(PitchClass.C);
    expect(pitchClassFromMidiNote(69)).toBe(PitchClass.A);
    expect(pitchClassFromMidiNote(72)).toBe(PitchClass.C);
    expect(pitchClassFromMidiNote(61)).toBe(PitchClass.CSharp);
  });

  it('chord MIDI notes', () => {
    const cMajor = createChord(PitchClass.C, CHORD_MAJOR);
    expect(chordMidiNotes(cMajor, 3)).toEqual([48, 52, 55]);

    const cMajorFirst = createChord(PitchClass.C, CHORD_MAJOR, Inversion.First);
    expect(chordMidiNotes(cMajorFirst, 3)).toEqual([52, 55, 60]);
  });
});
