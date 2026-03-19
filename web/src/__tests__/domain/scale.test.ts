import { describe, it, expect } from 'vitest';
import { PitchClass } from '../../domain/pitchClass.js';
import { MAJOR, NATURAL_MINOR } from '../../domain/scaleType.js';
import { type Scale, scalePitchClasses, scaleContains, scaleDegree } from '../../domain/scale.js';

describe('Scale Construction', () => {
  it('builds C major scale', () => {
    const scale: Scale = { root: PitchClass.C, scaleType: MAJOR };
    expect(scalePitchClasses(scale)).toEqual([
      PitchClass.C, PitchClass.D, PitchClass.E, PitchClass.F,
      PitchClass.G, PitchClass.A, PitchClass.B,
    ]);
  });

  it('builds A natural minor scale', () => {
    const scale: Scale = { root: PitchClass.A, scaleType: NATURAL_MINOR };
    expect(scalePitchClasses(scale)).toEqual([
      PitchClass.A, PitchClass.B, PitchClass.C, PitchClass.D,
      PitchClass.E, PitchClass.F, PitchClass.G,
    ]);
  });

  it('checks pitch class containment', () => {
    const scale: Scale = { root: PitchClass.C, scaleType: MAJOR };
    expect(scaleContains(scale, PitchClass.C)).toBe(true);
    expect(scaleContains(scale, PitchClass.E)).toBe(true);
    expect(scaleContains(scale, PitchClass.CSharp)).toBe(false);
    expect(scaleContains(scale, PitchClass.FSharp)).toBe(false);
  });

  it('returns correct scale degrees', () => {
    const scale: Scale = { root: PitchClass.C, scaleType: MAJOR };
    expect(scaleDegree(scale, PitchClass.C)).toBe(1);
    expect(scaleDegree(scale, PitchClass.D)).toBe(2);
    expect(scaleDegree(scale, PitchClass.G)).toBe(5);
    expect(scaleDegree(scale, PitchClass.B)).toBe(7);
    expect(scaleDegree(scale, PitchClass.FSharp)).toBeNull();
  });

  it('builds G major scale', () => {
    const scale: Scale = { root: PitchClass.G, scaleType: MAJOR };
    expect(scalePitchClasses(scale)).toEqual([
      PitchClass.G, PitchClass.A, PitchClass.B, PitchClass.C,
      PitchClass.D, PitchClass.E, PitchClass.FSharp,
    ]);
  });
});
