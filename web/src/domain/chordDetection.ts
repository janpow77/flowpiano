import { type PitchClass } from './pitchClass.js';
import { ALL_CHORD_TYPES } from './chordType.js';
import { Inversion } from './inversion.js';
import { type Chord, createChord } from './chord.js';

function determineInversion(root: number, bassPC: number, intervals: readonly number[]): Inversion {
  if (bassPC === root) return Inversion.Root;
  const chordPCs = intervals.map(i => (root + i) % 12);
  const bassIndex = chordPCs.indexOf(bassPC);
  switch (bassIndex) {
    case 1: return Inversion.First;
    case 2: return Inversion.Second;
    case 3: return Inversion.Third;
    default: return Inversion.Root;
  }
}

export function detect(midiNotes: number[]): Chord | null {
  const pitchClassValues = new Set(midiNotes.map(n => (((n % 12) + 12) % 12)));
  if (pitchClassValues.size < 3) return null;

  const sortedPC = [...pitchClassValues].sort((a, b) => a - b);
  const bassNote = Math.min(...midiNotes);
  const bassPitchClass = ((bassNote % 12) + 12) % 12;

  for (const chordType of ALL_CHORD_TYPES) {
    for (const potentialRoot of sortedPC) {
      const expectedIntervals = new Set(chordType.intervals);
      const actualIntervals = new Set(sortedPC.map(pc => ((pc - potentialRoot) + 12) % 12));

      if (expectedIntervals.size !== actualIntervals.size) continue;
      let match = true;
      for (const v of expectedIntervals) {
        if (!actualIntervals.has(v)) { match = false; break; }
      }
      if (!match) continue;

      const root = potentialRoot as PitchClass;
      const inversion = determineInversion(potentialRoot, bassPitchClass, chordType.intervals);
      return createChord(root, chordType, inversion);
    }
  }

  return null;
}

export function detectAll(midiNotes: number[]): Chord[] {
  const pitchClassValues = new Set(midiNotes.map(n => (((n % 12) + 12) % 12)));
  if (pitchClassValues.size < 3) return [];

  const sortedPC = [...pitchClassValues].sort((a, b) => a - b);
  const bassNote = Math.min(...midiNotes);
  const bassPitchClass = ((bassNote % 12) + 12) % 12;
  const results: Chord[] = [];

  for (const chordType of ALL_CHORD_TYPES) {
    for (const potentialRoot of sortedPC) {
      const expectedIntervals = new Set(chordType.intervals);
      const actualIntervals = new Set(sortedPC.map(pc => ((pc - potentialRoot) + 12) % 12));

      if (expectedIntervals.size !== actualIntervals.size) continue;
      let match = true;
      for (const v of expectedIntervals) {
        if (!actualIntervals.has(v)) { match = false; break; }
      }
      if (!match) continue;

      const root = potentialRoot as PitchClass;
      const inversion = determineInversion(potentialRoot, bassPitchClass, chordType.intervals);
      results.push(createChord(root, chordType, inversion));
    }
  }

  return results;
}
