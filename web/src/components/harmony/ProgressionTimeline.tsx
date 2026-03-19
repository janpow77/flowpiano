import { pitchClassGermanName } from '../../domain/pitchClass.js';
import { chordQualitySymbol } from '../../domain/chordQuality.js';
import { degreeColor } from '../../utils/degreeColors.js';
import type { ProgressionTemplate } from '../../domain/progressionTemplate.js';
import type { Scale } from '../../domain/scale.js';
import { resolveProgression } from '../../domain/progressionTemplate.js';

interface ProgressionTimelineProps {
  template: ProgressionTemplate;
  scale: Scale;
  currentIndex: number;
  completedCount: number;
}

export function ProgressionTimeline({ template, scale, currentIndex }: ProgressionTimelineProps) {
  const resolved = resolveProgression(template, scale);

  return (
    <div className="flex justify-center items-center gap-1 py-3 px-4 overflow-x-auto">
      {resolved.map((dc, i) => {
        const isCurrent = i === currentIndex;
        const isDone = i < currentIndex;
        const color = degreeColor(dc.degree);

        return (
          <div key={i} className="flex items-center">
            <div
              className="flex flex-col items-center rounded px-2 py-1.5 min-w-[50px] transition-all"
              style={{
                backgroundColor: isCurrent ? color + '30' : isDone ? color + '15' : '#1f2937',
                borderColor: isCurrent ? color : 'transparent',
                borderWidth: '2px',
                borderStyle: 'solid',
                opacity: isDone ? 0.6 : 1,
              }}
            >
              <span className="text-xs font-bold" style={{ color }}>
                {dc.romanNumeral}
              </span>
              <span className="text-sm text-gray-300">
                {pitchClassGermanName(dc.root)}{chordQualitySymbol(dc.chordType.quality)}
              </span>
              {isDone && <span className="text-green-400 text-xs">✓</span>}
            </div>
            {i < resolved.length - 1 && (
              <span className="text-gray-600 mx-0.5">→</span>
            )}
          </div>
        );
      })}
    </div>
  );
}
