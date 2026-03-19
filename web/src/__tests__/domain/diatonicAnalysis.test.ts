import { describe, it, expect } from 'vitest';
import { PitchClass } from '../../domain/pitchClass.js';
import { MAJOR, NATURAL_MINOR } from '../../domain/scaleType.js';
import { ChordQuality } from '../../domain/chordQuality.js';
import { HarmonicFunction } from '../../domain/harmonicFunction.js';
import { CHORD_MAJOR } from '../../domain/chordType.js';
import { createChord } from '../../domain/chord.js';
import { diatonicChords, analyze } from '../../domain/diatonicAnalysis.js';
import type { Scale } from '../../domain/scale.js';

describe('Diatonic Chords', () => {
  it('builds 7 diatonic chords in C major', () => {
    const scale: Scale = { root: PitchClass.C, scaleType: MAJOR };
    const chords = diatonicChords(scale);

    expect(chords).toHaveLength(7);

    // I = C major
    expect(chords[0].root).toBe(PitchClass.C);
    expect(chords[0].chordType.quality).toBe(ChordQuality.Major);
    expect(chords[0].romanNumeral).toBe('I');

    // ii = D minor
    expect(chords[1].root).toBe(PitchClass.D);
    expect(chords[1].chordType.quality).toBe(ChordQuality.Minor);
    expect(chords[1].romanNumeral).toBe('ii');

    // iii = E minor
    expect(chords[2].root).toBe(PitchClass.E);
    expect(chords[2].chordType.quality).toBe(ChordQuality.Minor);

    // IV = F major
    expect(chords[3].root).toBe(PitchClass.F);
    expect(chords[3].chordType.quality).toBe(ChordQuality.Major);
    expect(chords[3].romanNumeral).toBe('IV');

    // V = G major
    expect(chords[4].root).toBe(PitchClass.G);
    expect(chords[4].chordType.quality).toBe(ChordQuality.Major);
    expect(chords[4].romanNumeral).toBe('V');

    // vi = A minor
    expect(chords[5].root).toBe(PitchClass.A);
    expect(chords[5].chordType.quality).toBe(ChordQuality.Minor);
    expect(chords[5].romanNumeral).toBe('vi');

    // vii° = B diminished
    expect(chords[6].root).toBe(PitchClass.B);
    expect(chords[6].chordType.quality).toBe(ChordQuality.Diminished);
  });

  it('builds diatonic chords in A minor', () => {
    const scale: Scale = { root: PitchClass.A, scaleType: NATURAL_MINOR };
    const chords = diatonicChords(scale);

    expect(chords).toHaveLength(7);
    expect(chords[0].root).toBe(PitchClass.A);
    expect(chords[0].chordType.quality).toBe(ChordQuality.Minor);
    expect(chords[0].romanNumeral).toBe('i');

    expect(chords[2].root).toBe(PitchClass.C);
    expect(chords[2].chordType.quality).toBe(ChordQuality.Major);
    expect(chords[2].romanNumeral).toBe('III');
  });

  it('has correct function labels for major key', () => {
    const scale: Scale = { root: PitchClass.C, scaleType: MAJOR };
    const chords = diatonicChords(scale);

    expect(chords[0].functionLabel).toBe('T');    // I = Tonika
    expect(chords[1].functionLabel).toBe('Sp');   // ii = Subdominant-Parallele
    expect(chords[2].functionLabel).toBe('Dp');   // iii = Dominant-Parallele
    expect(chords[3].functionLabel).toBe('S');    // IV = Subdominante
    expect(chords[4].functionLabel).toBe('D');    // V = Dominante
    expect(chords[5].functionLabel).toBe('Tp');   // vi = Tonika-Parallele
  });
});

describe('Functional Analysis', () => {
  it('analyzes chord in key', () => {
    const scale: Scale = { root: PitchClass.C, scaleType: MAJOR };
    const chord = createChord(PitchClass.F, CHORD_MAJOR);
    const analysis = analyze(chord, scale);

    expect(analysis).not.toBeNull();
    expect(analysis!.degree).toBe(4);
    expect(analysis!.romanNumeral).toBe('IV');
    expect(analysis!.harmonicFunction).toBe(HarmonicFunction.Subdominant);
  });

  it('returns null for non-diatonic chord', () => {
    const scale: Scale = { root: PitchClass.C, scaleType: MAJOR };
    const chord = createChord(PitchClass.FSharp, CHORD_MAJOR);
    const analysis = analyze(chord, scale);

    expect(analysis).toBeNull();
  });
});
