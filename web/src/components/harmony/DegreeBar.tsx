import { pitchClassGermanName } from '../../domain/pitchClass.js';
import type { DiatonicChord } from '../../domain/diatonicChord.js';
import { degreeColor } from '../../utils/degreeColors.js';

interface DegreeBarProps {
  diatonicChords: DiatonicChord[];
  activeDegree?: number;
}

export function DegreeBar({ diatonicChords, activeDegree }: DegreeBarProps) {
  return (
    <div className="flex justify-center gap-1 py-2 px-4">
      {diatonicChords.map(dc => {
        const isActive = activeDegree === dc.degree;
        return (
          <div
            key={dc.degree}
            className="flex flex-col items-center text-xs w-14 py-1 rounded transition-all"
            style={{
              backgroundColor: isActive ? degreeColor(dc.degree) + '33' : 'transparent',
              borderBottom: `3px solid ${degreeColor(dc.degree)}`,
            }}
          >
            <span className="font-medium" style={{ color: degreeColor(dc.degree) }}>
              {dc.functionLabel}
            </span>
            <span className="text-gray-400">{dc.romanNumeral}</span>
            <span className="text-gray-500">{pitchClassGermanName(dc.root)}</span>
          </div>
        );
      })}
    </div>
  );
}
