import { pitchClassGermanName } from '../../domain/pitchClass.js';
import { chordQualitySymbol } from '../../domain/chordQuality.js';
import type { DiatonicChord } from '../../domain/diatonicChord.js';
import { degreeColor } from '../../utils/degreeColors.js';

interface DiatonicOverviewProps {
  diatonicChords: DiatonicChord[];
  activeDegree?: number;
}

export function DiatonicOverview({ diatonicChords, activeDegree }: DiatonicOverviewProps) {
  return (
    <div className="flex justify-center gap-2 py-3 px-4">
      {diatonicChords.map(dc => {
        const isActive = activeDegree === dc.degree;
        const color = degreeColor(dc.degree);
        return (
          <div
            key={dc.degree}
            className="flex flex-col items-center rounded-lg px-3 py-2 transition-all min-w-[60px]"
            style={{
              backgroundColor: isActive ? color + '30' : '#1f2937',
              borderColor: isActive ? color : '#374151',
              borderWidth: '2px',
              borderStyle: 'solid',
              transform: isActive ? 'scale(1.08)' : 'scale(1)',
            }}
          >
            <span className="text-sm font-bold" style={{ color }}>
              {dc.romanNumeral}
            </span>
            <span className="text-base font-semibold text-gray-200">
              {pitchClassGermanName(dc.root)}{chordQualitySymbol(dc.chordType.quality)}
            </span>
            <span className="text-xs" style={{ color }}>
              {dc.functionLabel}
            </span>
          </div>
        );
      })}
    </div>
  );
}
