import type { ChordQuality } from './chordQuality.js';

export interface ProgressionStep {
  readonly degree: number;          // 1-7
  readonly label: string;           // e.g. "I", "V", "vi"
  readonly qualityOverride?: ChordQuality;  // undefined = use diatonic default
}
