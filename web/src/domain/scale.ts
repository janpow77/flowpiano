import { type PitchClass, transposed } from './pitchClass.js';
import type { ScaleType } from './scaleType.js';

export interface Scale {
  readonly root: PitchClass;
  readonly scaleType: ScaleType;
}

export function scalePitchClasses(scale: Scale): PitchClass[] {
  return scale.scaleType.intervals.map(i => transposed(scale.root, i));
}

export function scaleContains(scale: Scale, pc: PitchClass): boolean {
  return scalePitchClasses(scale).includes(pc);
}

export function scaleDegree(scale: Scale, pc: PitchClass): number | null {
  const index = scalePitchClasses(scale).indexOf(pc);
  return index === -1 ? null : index + 1;
}
