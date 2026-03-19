import { describe, it, expect } from 'vitest';
import { PitchClass } from '../../domain/pitchClass.js';
import { ChordQuality } from '../../domain/chordQuality.js';
import { Inversion } from '../../domain/inversion.js';
import { detect } from '../../domain/chordDetection.js';

describe('Chord Detection', () => {
  it('detects C major triad', () => {
    const chord = detect([60, 64, 67]); // C E G
    expect(chord).not.toBeNull();
    expect(chord!.root).toBe(PitchClass.C);
    expect(chord!.chordType.quality).toBe(ChordQuality.Major);
    expect(chord!.inversion).toBe(Inversion.Root);
  });

  it('detects C major first inversion', () => {
    const chord = detect([64, 67, 72]); // E G C
    expect(chord).not.toBeNull();
    expect(chord!.root).toBe(PitchClass.C);
    expect(chord!.chordType.quality).toBe(ChordQuality.Major);
    expect(chord!.inversion).toBe(Inversion.First);
  });

  it('detects A minor triad', () => {
    const chord = detect([57, 60, 64]); // A C E
    expect(chord).not.toBeNull();
    expect(chord!.root).toBe(PitchClass.A);
    expect(chord!.chordType.quality).toBe(ChordQuality.Minor);
  });

  it('detects G7', () => {
    const chord = detect([55, 59, 62, 65]); // G B D F
    expect(chord).not.toBeNull();
    expect(chord!.root).toBe(PitchClass.G);
    expect(chord!.chordType.quality).toBe(ChordQuality.Dominant7);
  });

  it('detects B diminished', () => {
    const chord = detect([59, 62, 65]); // B D F
    expect(chord).not.toBeNull();
    expect(chord!.root).toBe(PitchClass.B);
    expect(chord!.chordType.quality).toBe(ChordQuality.Diminished);
  });

  it('returns null for two notes', () => {
    expect(detect([60, 64])).toBeNull();
  });

  it('returns null for empty notes', () => {
    expect(detect([])).toBeNull();
  });

  it('detects C major across octaves', () => {
    const chord = detect([48, 64, 79]); // C3 E4 G5
    expect(chord).not.toBeNull();
    expect(chord!.root).toBe(PitchClass.C);
    expect(chord!.chordType.quality).toBe(ChordQuality.Major);
  });
});
