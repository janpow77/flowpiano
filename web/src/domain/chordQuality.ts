export enum ChordQuality {
  Major = 'major',
  Minor = 'minor',
  Diminished = 'diminished',
  Augmented = 'augmented',
  Dominant7 = 'dominant7',
  Major7 = 'major7',
  Minor7 = 'minor7',
  Diminished7 = 'diminished7',
}

export function chordQualitySymbol(q: ChordQuality): string {
  const symbols: Record<ChordQuality, string> = {
    [ChordQuality.Major]: '',
    [ChordQuality.Minor]: 'm',
    [ChordQuality.Diminished]: '\u00B0',
    [ChordQuality.Augmented]: '+',
    [ChordQuality.Dominant7]: '7',
    [ChordQuality.Major7]: 'maj7',
    [ChordQuality.Minor7]: 'm7',
    [ChordQuality.Diminished7]: '\u00B07',
  };
  return symbols[q];
}

export function chordQualityGermanName(q: ChordQuality): string {
  const names: Record<ChordQuality, string> = {
    [ChordQuality.Major]: 'Dur',
    [ChordQuality.Minor]: 'Moll',
    [ChordQuality.Diminished]: 'Vermindert',
    [ChordQuality.Augmented]: 'Übermäßig',
    [ChordQuality.Dominant7]: 'Dominant-7',
    [ChordQuality.Major7]: 'Major-7',
    [ChordQuality.Minor7]: 'Moll-7',
    [ChordQuality.Diminished7]: 'Verm.-7',
  };
  return names[q];
}
