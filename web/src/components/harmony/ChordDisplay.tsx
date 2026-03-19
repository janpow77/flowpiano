import type { Chord } from '../../domain/chord.js';
import { chordGermanDisplayName } from '../../domain/chord.js';
import { Inversion } from '../../domain/inversion.js';
import type { DiatonicChord } from '../../domain/diatonicChord.js';
import { degreeColor } from '../../utils/degreeColors.js';

interface ChordDisplayProps {
  chord: Chord | null;
  analysis: DiatonicChord | null;
}

const INVERSION_LABELS: Record<Inversion, string> = {
  [Inversion.Root]: 'Grundstellung',
  [Inversion.First]: '1. Umkehrung',
  [Inversion.Second]: '2. Umkehrung',
  [Inversion.Third]: '3. Umkehrung',
};

export function ChordDisplay({ chord, analysis }: ChordDisplayProps) {
  if (!chord) {
    return (
      <div className="text-center py-4">
        <div className="text-2xl text-gray-600">—</div>
        <div className="text-sm text-gray-500">Spiele einen Akkord</div>
      </div>
    );
  }

  const color = analysis ? degreeColor(analysis.degree) : '#888';

  return (
    <div className="text-center py-4">
      <div className="text-4xl font-bold" style={{ color }}>
        {chordGermanDisplayName(chord)}
      </div>
      {chord.inversion !== Inversion.Root && (
        <div className="text-sm text-gray-400 mt-1">
          {INVERSION_LABELS[chord.inversion]}
        </div>
      )}
      {analysis && (
        <div className="text-lg mt-1" style={{ color }}>
          {analysis.romanNumeral} ({analysis.functionLabel})
        </div>
      )}
    </div>
  );
}
