export enum HarmonicFunction {
  Tonic = 'tonic',
  Subdominant = 'subdominant',
  Dominant = 'dominant',
}

export function harmonicFunctionGermanName(fn: HarmonicFunction): string {
  const names: Record<HarmonicFunction, string> = {
    [HarmonicFunction.Tonic]: 'Tonika',
    [HarmonicFunction.Subdominant]: 'Subdominante',
    [HarmonicFunction.Dominant]: 'Dominante',
  };
  return names[fn];
}

export function harmonicFunctionAbbreviation(fn: HarmonicFunction): string {
  const abbrs: Record<HarmonicFunction, string> = {
    [HarmonicFunction.Tonic]: 'T',
    [HarmonicFunction.Subdominant]: 'S',
    [HarmonicFunction.Dominant]: 'D',
  };
  return abbrs[fn];
}
