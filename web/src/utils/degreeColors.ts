import { HarmonicFunction } from '../domain/harmonicFunction.js';

export const DEGREE_COLORS: readonly string[] = [
  '#E84D3D', // I
  '#D4B038', // ii
  '#A8D65C', // iii
  '#26AD61', // IV
  '#00BDD4', // V
  '#3399DB', // vi
  '#9C59B5', // vii
];

export function degreeColor(degree: number): string {
  if (degree < 1 || degree > 7) return '#666';
  return DEGREE_COLORS[degree - 1];
}

export const FUNCTION_COLORS: Record<HarmonicFunction, string> = {
  [HarmonicFunction.Tonic]: '#3399DB',
  [HarmonicFunction.Subdominant]: '#26AD61',
  [HarmonicFunction.Dominant]: '#E8943D',
};

export function functionColor(fn: HarmonicFunction): string {
  return FUNCTION_COLORS[fn];
}
