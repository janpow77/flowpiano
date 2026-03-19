import { pitchClassName, pitchClassFromMidiNote } from '../domain/pitchClass.js';

export function midiNoteToFrequency(note: number): number {
  return 440 * Math.pow(2, (note - 69) / 12);
}

export function midiNoteToName(note: number): string {
  const pc = pitchClassFromMidiNote(note);
  const octave = Math.floor(note / 12) - 1;
  return `${pitchClassName(pc)}${octave}`;
}

export function midiNoteOctave(note: number): number {
  return Math.floor(note / 12) - 1;
}
