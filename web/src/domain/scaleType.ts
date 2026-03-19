export interface ScaleType {
  readonly name: string;
  readonly intervals: readonly number[];
}

export const MAJOR: ScaleType = { name: 'Major', intervals: [0, 2, 4, 5, 7, 9, 11] };
export const NATURAL_MINOR: ScaleType = { name: 'Natural Minor', intervals: [0, 2, 3, 5, 7, 8, 10] };
export const HARMONIC_MINOR: ScaleType = { name: 'Harmonic Minor', intervals: [0, 2, 3, 5, 7, 8, 11] };
