import { type PitchClass, pitchClassName, pitchClassGermanName, transposed } from './pitchClass.js';
import type { ChordType } from './chordType.js';
import { chordQualitySymbol } from './chordQuality.js';
import { Inversion } from './inversion.js';

export interface Chord {
  readonly root: PitchClass;
  readonly chordType: ChordType;
  readonly inversion: Inversion;
}

export function createChord(root: PitchClass, chordType: ChordType, inversion: Inversion = Inversion.Root): Chord {
  return { root, chordType, inversion };
}

export function chordPitchClasses(chord: Chord): PitchClass[] {
  return chord.chordType.intervals.map(i => transposed(chord.root, i));
}

export function chordDisplayName(chord: Chord): string {
  return pitchClassName(chord.root) + chordQualitySymbol(chord.chordType.quality);
}

export function chordGermanDisplayName(chord: Chord): string {
  return pitchClassGermanName(chord.root) + chordQualitySymbol(chord.chordType.quality);
}

export function chordMidiNotes(chord: Chord, octave: number = 3): number[] {
  const baseMidi = (octave + 1) * 12 + chord.root;
  const notes = chord.chordType.intervals.map(i => baseMidi + i);

  switch (chord.inversion) {
    case Inversion.Root:
      break;
    case Inversion.First:
      if (notes.length >= 3) {
        notes[0] += 12;
        notes.sort((a, b) => a - b);
      }
      break;
    case Inversion.Second:
      if (notes.length >= 3) {
        notes[0] += 12;
        notes[1] += 12;
        notes.sort((a, b) => a - b);
      }
      break;
    case Inversion.Third:
      if (notes.length >= 4) {
        notes[0] += 12;
        notes[1] += 12;
        notes[2] += 12;
        notes.sort((a, b) => a - b);
      }
      break;
  }

  return notes;
}
