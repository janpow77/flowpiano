export enum PitchClass {
  C = 0,
  CSharp = 1,
  D = 2,
  DSharp = 3,
  E = 4,
  F = 5,
  FSharp = 6,
  G = 7,
  GSharp = 8,
  A = 9,
  ASharp = 10,
  B = 11,
}

export const ALL_PITCH_CLASSES: readonly PitchClass[] = [
  PitchClass.C, PitchClass.CSharp, PitchClass.D, PitchClass.DSharp,
  PitchClass.E, PitchClass.F, PitchClass.FSharp, PitchClass.G,
  PitchClass.GSharp, PitchClass.A, PitchClass.ASharp, PitchClass.B,
];

export function pitchClassFromMidiNote(midiNote: number): PitchClass {
  return (((midiNote % 12) + 12) % 12) as PitchClass;
}

export function pitchClassName(pc: PitchClass): string {
  const names: Record<PitchClass, string> = {
    [PitchClass.C]: 'C',
    [PitchClass.CSharp]: 'C#',
    [PitchClass.D]: 'D',
    [PitchClass.DSharp]: 'D#',
    [PitchClass.E]: 'E',
    [PitchClass.F]: 'F',
    [PitchClass.FSharp]: 'F#',
    [PitchClass.G]: 'G',
    [PitchClass.GSharp]: 'G#',
    [PitchClass.A]: 'A',
    [PitchClass.ASharp]: 'A#',
    [PitchClass.B]: 'B',
  };
  return names[pc];
}

export function pitchClassGermanName(pc: PitchClass): string {
  const names: Record<PitchClass, string> = {
    [PitchClass.C]: 'C',
    [PitchClass.CSharp]: 'Cis',
    [PitchClass.D]: 'D',
    [PitchClass.DSharp]: 'Dis',
    [PitchClass.E]: 'E',
    [PitchClass.F]: 'F',
    [PitchClass.FSharp]: 'Fis',
    [PitchClass.G]: 'G',
    [PitchClass.GSharp]: 'Gis',
    [PitchClass.A]: 'A',
    [PitchClass.ASharp]: 'B',
    [PitchClass.B]: 'H',
  };
  return names[pc];
}

export function pitchClassFlatName(pc: PitchClass): string {
  const names: Record<PitchClass, string> = {
    [PitchClass.C]: 'C',
    [PitchClass.CSharp]: 'Db',
    [PitchClass.D]: 'D',
    [PitchClass.DSharp]: 'Eb',
    [PitchClass.E]: 'E',
    [PitchClass.F]: 'F',
    [PitchClass.FSharp]: 'Gb',
    [PitchClass.G]: 'G',
    [PitchClass.GSharp]: 'Ab',
    [PitchClass.A]: 'A',
    [PitchClass.ASharp]: 'Bb',
    [PitchClass.B]: 'B',
  };
  return names[pc];
}

export function transposed(pc: PitchClass, semitones: number): PitchClass {
  return (((pc + semitones) % 12 + 12) % 12) as PitchClass;
}
