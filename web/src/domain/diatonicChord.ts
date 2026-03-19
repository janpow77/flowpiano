import type { PitchClass } from './pitchClass.js';
import type { ChordType } from './chordType.js';
import type { HarmonicFunction } from './harmonicFunction.js';

export interface DiatonicChord {
  readonly degree: number;           // 1-7
  readonly romanNumeral: string;
  readonly chordType: ChordType;
  readonly root: PitchClass;
  readonly harmonicFunction: HarmonicFunction;
  readonly functionLabel: string;    // "T", "Sp", "Dp", "S", "D", "Tp", "D⁷"
  readonly description: string;
}
