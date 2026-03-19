import { ChordQuality } from './chordQuality.js';

export interface ChordType {
  readonly quality: ChordQuality;
  readonly intervals: readonly number[];
}

export const CHORD_MAJOR: ChordType = { quality: ChordQuality.Major, intervals: [0, 4, 7] };
export const CHORD_MINOR: ChordType = { quality: ChordQuality.Minor, intervals: [0, 3, 7] };
export const CHORD_DIMINISHED: ChordType = { quality: ChordQuality.Diminished, intervals: [0, 3, 6] };
export const CHORD_AUGMENTED: ChordType = { quality: ChordQuality.Augmented, intervals: [0, 4, 8] };
export const CHORD_DOMINANT7: ChordType = { quality: ChordQuality.Dominant7, intervals: [0, 4, 7, 10] };
export const CHORD_MAJOR7: ChordType = { quality: ChordQuality.Major7, intervals: [0, 4, 7, 11] };
export const CHORD_MINOR7: ChordType = { quality: ChordQuality.Minor7, intervals: [0, 3, 7, 10] };
export const CHORD_DIMINISHED7: ChordType = { quality: ChordQuality.Diminished7, intervals: [0, 3, 6, 9] };

export const ALL_CHORD_TYPES: readonly ChordType[] = [
  CHORD_MAJOR, CHORD_MINOR, CHORD_DIMINISHED, CHORD_AUGMENTED,
  CHORD_DOMINANT7, CHORD_MAJOR7, CHORD_MINOR7, CHORD_DIMINISHED7,
];

export function chordTypeForQuality(quality: ChordQuality): ChordType {
  const map: Record<ChordQuality, ChordType> = {
    [ChordQuality.Major]: CHORD_MAJOR,
    [ChordQuality.Minor]: CHORD_MINOR,
    [ChordQuality.Diminished]: CHORD_DIMINISHED,
    [ChordQuality.Augmented]: CHORD_AUGMENTED,
    [ChordQuality.Dominant7]: CHORD_DOMINANT7,
    [ChordQuality.Major7]: CHORD_MAJOR7,
    [ChordQuality.Minor7]: CHORD_MINOR7,
    [ChordQuality.Diminished7]: CHORD_DIMINISHED7,
  };
  return map[quality];
}
