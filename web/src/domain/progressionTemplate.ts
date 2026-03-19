import { ChordQuality } from './chordQuality.js';
import { CHORD_MAJOR, CHORD_MINOR, CHORD_DIMINISHED, CHORD_AUGMENTED, type ChordType } from './chordType.js';
import type { Scale } from './scale.js';
import type { ProgressionStep } from './progressionStep.js';
import type { DiatonicChord } from './diatonicChord.js';
import { diatonicChords } from './diatonicAnalysis.js';

export interface ProgressionTemplate {
  readonly id: string;
  readonly name: string;
  readonly composer: string;
  readonly era: string;
  readonly steps: readonly ProgressionStep[];
  readonly isMajor: boolean;
  readonly description: string;
}

function chordTypeForQualityOverride(quality: ChordQuality, fallback: ChordType): ChordType {
  switch (quality) {
    case ChordQuality.Major: return CHORD_MAJOR;
    case ChordQuality.Minor: return CHORD_MINOR;
    case ChordQuality.Diminished: return CHORD_DIMINISHED;
    case ChordQuality.Augmented: return CHORD_AUGMENTED;
    default: return fallback;
  }
}

export function resolveProgression(template: ProgressionTemplate, scale: Scale): DiatonicChord[] {
  const diatonic = diatonicChords(scale);
  const result: DiatonicChord[] = [];

  for (const step of template.steps) {
    if (step.degree < 1 || step.degree > diatonic.length) continue;
    const dc = diatonic[step.degree - 1];

    if (step.qualityOverride != null) {
      const overriddenType = chordTypeForQualityOverride(step.qualityOverride, dc.chordType);
      result.push({
        ...dc,
        romanNumeral: step.label,
        chordType: overriddenType,
      });
    } else {
      result.push(dc);
    }
  }

  return result;
}

// --- Built-in Progressions ---

export const PACHELBEL: ProgressionTemplate = {
  id: 'pachelbel',
  name: 'Pachelbel-Kanon',
  composer: 'Johann Pachelbel',
  era: '~1680',
  steps: [
    { degree: 1, label: 'I' },
    { degree: 5, label: 'V' },
    { degree: 6, label: 'vi' },
    { degree: 3, label: 'iii' },
    { degree: 4, label: 'IV' },
    { degree: 1, label: 'I' },
    { degree: 4, label: 'IV' },
    { degree: 5, label: 'V' },
  ],
  isMajor: true,
  description: 'Der berühmte Kanon in D-Dur',
};

export const FIFTIES: ProgressionTemplate = {
  id: 'fifties',
  name: '50s Progression',
  composer: 'Pop/Doo-Wop',
  era: '1950er',
  steps: [
    { degree: 1, label: 'I' },
    { degree: 6, label: 'vi' },
    { degree: 4, label: 'IV' },
    { degree: 5, label: 'V' },
  ],
  isMajor: true,
  description: 'Stand By Me, Earth Angel, etc.',
};

export const AXIS_OF_AWESOME: ProgressionTemplate = {
  id: 'axis',
  name: 'Axis of Awesome',
  composer: 'Pop',
  era: 'Modern',
  steps: [
    { degree: 1, label: 'I' },
    { degree: 5, label: 'V' },
    { degree: 6, label: 'vi' },
    { degree: 4, label: 'IV' },
  ],
  isMajor: true,
  description: 'Let It Be, No Woman No Cry, etc.',
};

export const ANDALUSIAN_MAJOR: ProgressionTemplate = {
  id: 'andalusian-major',
  name: 'Andalusische Kadenz',
  composer: 'Flamenco',
  era: 'Traditionell',
  steps: [
    { degree: 6, label: 'vi' },
    { degree: 5, label: 'V' },
    { degree: 4, label: 'IV' },
    { degree: 3, label: 'iii' },
  ],
  isMajor: true,
  description: 'Typisch für spanische Musik',
};

export const JAZZ_TWO_FIVE_ONE: ProgressionTemplate = {
  id: 'jazz-251',
  name: 'Jazz II-V-I',
  composer: 'Jazz',
  era: 'Klassiker',
  steps: [
    { degree: 2, label: 'ii' },
    { degree: 5, label: 'V' },
    { degree: 1, label: 'I' },
  ],
  isMajor: true,
  description: 'Die wichtigste Jazz-Kadenz',
};

export const BLUES: ProgressionTemplate = {
  id: 'blues',
  name: '12-Takt Blues',
  composer: 'Blues/Rock',
  era: 'Klassiker',
  steps: [
    { degree: 1, label: 'I' },
    { degree: 1, label: 'I' },
    { degree: 1, label: 'I' },
    { degree: 1, label: 'I' },
    { degree: 4, label: 'IV' },
    { degree: 4, label: 'IV' },
    { degree: 1, label: 'I' },
    { degree: 1, label: 'I' },
    { degree: 5, label: 'V' },
    { degree: 4, label: 'IV' },
    { degree: 1, label: 'I' },
    { degree: 5, label: 'V' },
  ],
  isMajor: true,
  description: '12-Takt-Blues-Schema',
};

export const MINOR_CADENCE: ProgressionTemplate = {
  id: 'minor-cadence',
  name: 'Moll-Kadenz',
  composer: 'Klassik',
  era: 'Traditionell',
  steps: [
    { degree: 1, label: 'i' },
    { degree: 4, label: 'iv' },
    { degree: 5, label: 'v' },
    { degree: 1, label: 'i' },
  ],
  isMajor: false,
  description: 'Klassische Moll-Kadenz',
};

export const ANDALUSIAN_MINOR: ProgressionTemplate = {
  id: 'andalusian-minor',
  name: 'Andalusische Kadenz (Moll)',
  composer: 'Flamenco',
  era: 'Traditionell',
  steps: [
    { degree: 1, label: 'i' },
    { degree: 7, label: 'VII' },
    { degree: 6, label: 'VI' },
    { degree: 5, label: 'V', qualityOverride: ChordQuality.Major },
  ],
  isMajor: false,
  description: 'Hit The Road Jack, etc.',
};

export const MINOR_POP: ProgressionTemplate = {
  id: 'minor-pop',
  name: 'Moll Pop',
  composer: 'Pop',
  era: 'Modern',
  steps: [
    { degree: 1, label: 'i' },
    { degree: 6, label: 'VI' },
    { degree: 7, label: 'VII' },
    { degree: 5, label: 'v' },
  ],
  isMajor: false,
  description: 'Beliebte Moll-Progression',
};

export const ALL_MAJOR_PROGRESSIONS: readonly ProgressionTemplate[] = [
  PACHELBEL, FIFTIES, AXIS_OF_AWESOME, ANDALUSIAN_MAJOR, JAZZ_TWO_FIVE_ONE, BLUES,
];

export const ALL_MINOR_PROGRESSIONS: readonly ProgressionTemplate[] = [
  MINOR_CADENCE, ANDALUSIAN_MINOR, MINOR_POP,
];

export const ALL_PROGRESSIONS: readonly ProgressionTemplate[] = [
  ...ALL_MAJOR_PROGRESSIONS, ...ALL_MINOR_PROGRESSIONS,
];
