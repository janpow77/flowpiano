import { describe, it, expect } from 'vitest';
import { PitchClass } from '../../domain/pitchClass.js';
import { MAJOR, NATURAL_MINOR } from '../../domain/scaleType.js';
import { ChordQuality } from '../../domain/chordQuality.js';
import type { Scale } from '../../domain/scale.js';
import { PACHELBEL, ANDALUSIAN_MINOR, resolveProgression } from '../../domain/progressionTemplate.js';

describe('Progressions', () => {
  it('Pachelbel has 8 steps', () => {
    expect(PACHELBEL.steps).toHaveLength(8);
    expect(PACHELBEL.steps[0].degree).toBe(1);
    expect(PACHELBEL.steps[1].degree).toBe(5);
    expect(PACHELBEL.steps[2].degree).toBe(6);
    expect(PACHELBEL.steps[3].degree).toBe(3);
  });

  it('resolves Pachelbel in C major', () => {
    const scale: Scale = { root: PitchClass.C, scaleType: MAJOR };
    const resolved = resolveProgression(PACHELBEL, scale);

    expect(resolved).toHaveLength(8);
    expect(resolved[0].root).toBe(PitchClass.C);   // I
    expect(resolved[1].root).toBe(PitchClass.G);   // V
    expect(resolved[2].root).toBe(PitchClass.A);   // vi
    expect(resolved[3].root).toBe(PitchClass.E);   // iii
    expect(resolved[4].root).toBe(PitchClass.F);   // IV
  });

  it('Andalusian minor resolves with major V override', () => {
    const scale: Scale = { root: PitchClass.A, scaleType: NATURAL_MINOR };
    const resolved = resolveProgression(ANDALUSIAN_MINOR, scale);

    expect(resolved).toHaveLength(4);
    expect(resolved[3].root).toBe(PitchClass.E);
    expect(resolved[3].chordType.quality).toBe(ChordQuality.Major);
  });
});
