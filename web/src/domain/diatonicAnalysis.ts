import type { Scale } from './scale.js';
import { scalePitchClasses } from './scale.js';
import { MAJOR } from './scaleType.js';
import { ChordQuality } from './chordQuality.js';
import { CHORD_MAJOR, CHORD_MINOR, CHORD_DIMINISHED, CHORD_AUGMENTED, type ChordType } from './chordType.js';
import { HarmonicFunction } from './harmonicFunction.js';
import type { DiatonicChord } from './diatonicChord.js';
import type { Chord } from './chord.js';

interface DiatonicTemplate {
  roman: string;
  quality: ChordQuality;
  function: HarmonicFunction;
  label: string;
  desc: string;
}

function chordTypeForQuality(quality: ChordQuality): ChordType {
  switch (quality) {
    case ChordQuality.Major: return CHORD_MAJOR;
    case ChordQuality.Minor: return CHORD_MINOR;
    case ChordQuality.Diminished: return CHORD_DIMINISHED;
    case ChordQuality.Augmented: return CHORD_AUGMENTED;
    default: return CHORD_MAJOR;
  }
}

export function diatonicChords(scale: Scale): DiatonicChord[] {
  const pcs = scalePitchClasses(scale);
  const isMajor = scale.scaleType === MAJOR;

  const templates: DiatonicTemplate[] = isMajor
    ? [
        { roman: 'I',       quality: ChordQuality.Major,      function: HarmonicFunction.Tonic,       label: 'T',   desc: 'Ruhepunkt' },
        { roman: 'ii',      quality: ChordQuality.Minor,      function: HarmonicFunction.Subdominant, label: 'Sp',  desc: 'Subdominant-Parallele' },
        { roman: 'iii',     quality: ChordQuality.Minor,      function: HarmonicFunction.Dominant,    label: 'Dp',  desc: 'Dominant-Parallele' },
        { roman: 'IV',      quality: ChordQuality.Major,      function: HarmonicFunction.Subdominant, label: 'S',   desc: 'Spannungsaufbau' },
        { roman: 'V',       quality: ChordQuality.Major,      function: HarmonicFunction.Dominant,    label: 'D',   desc: 'Höchste Spannung' },
        { roman: 'vi',      quality: ChordQuality.Minor,      function: HarmonicFunction.Tonic,       label: 'Tp',  desc: 'Tonika-Parallele' },
        { roman: 'vii\u00B0', quality: ChordQuality.Diminished, function: HarmonicFunction.Dominant,  label: 'D\u2077', desc: 'Leittonakkord' },
      ]
    : [
        { roman: 'i',       quality: ChordQuality.Minor,      function: HarmonicFunction.Tonic,       label: 't',    desc: 'Ruhepunkt' },
        { roman: 'ii\u00B0', quality: ChordQuality.Diminished, function: HarmonicFunction.Subdominant, label: 's\u00B0', desc: 'Subdominant-Vertreter' },
        { roman: 'III',     quality: ChordQuality.Major,      function: HarmonicFunction.Tonic,       label: 'tP',   desc: 'Tonikaparallele' },
        { roman: 'iv',      quality: ChordQuality.Minor,      function: HarmonicFunction.Subdominant, label: 's',    desc: 'Spannungsaufbau' },
        { roman: 'v',       quality: ChordQuality.Minor,      function: HarmonicFunction.Dominant,    label: 'd',    desc: 'Moll-Dominante' },
        { roman: 'VI',      quality: ChordQuality.Major,      function: HarmonicFunction.Subdominant, label: 'sP',   desc: 'Subdominantparallele' },
        { roman: 'VII',     quality: ChordQuality.Major,      function: HarmonicFunction.Dominant,    label: 'VII',  desc: 'Subtonikaakkord' },
      ];

  return templates.map((tmpl, index) => ({
    degree: index + 1,
    romanNumeral: tmpl.roman,
    chordType: chordTypeForQuality(tmpl.quality),
    root: pcs[index],
    harmonicFunction: tmpl.function,
    functionLabel: tmpl.label,
    description: tmpl.desc,
  }));
}

export function analyze(chord: Chord, scale: Scale): DiatonicChord | null {
  const diatonic = diatonicChords(scale);
  return diatonic.find(dc =>
    dc.root === chord.root && dc.chordType.quality === chord.chordType.quality
  ) ?? null;
}

export function analyzeByRoot(chord: Chord, scale: Scale): DiatonicChord | null {
  const diatonic = diatonicChords(scale);
  return diatonic.find(dc => dc.root === chord.root) ?? null;
}
