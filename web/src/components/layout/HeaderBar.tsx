import { PitchClass, ALL_PITCH_CLASSES, pitchClassGermanName } from '../../domain/pitchClass.js';
import { MAJOR, NATURAL_MINOR, type ScaleType } from '../../domain/scaleType.js';

interface HeaderBarProps {
  selectedKey: PitchClass;
  selectedScaleType: ScaleType;
  onKeyChange: (key: PitchClass) => void;
  onScaleTypeChange: (st: ScaleType) => void;
  children?: React.ReactNode;
}

export function HeaderBar({ selectedKey, selectedScaleType, onKeyChange, onScaleTypeChange, children }: HeaderBarProps) {
  const isMajor = selectedScaleType === MAJOR;

  return (
    <div className="flex items-center justify-between px-4 py-2 bg-gray-900 border-b border-gray-700">
      <div className="flex items-center gap-3">
        <select
          value={selectedKey}
          onChange={e => onKeyChange(Number(e.target.value) as PitchClass)}
          className="bg-gray-700 text-gray-200 rounded-lg px-3 py-1.5 text-sm border border-gray-600 focus:outline-none focus:border-blue-500"
        >
          {ALL_PITCH_CLASSES.map(pc => (
            <option key={pc} value={pc}>{pitchClassGermanName(pc)}</option>
          ))}
        </select>

        <div className="flex rounded-lg overflow-hidden border border-gray-600">
          <button
            onClick={() => onScaleTypeChange(MAJOR)}
            className={`px-3 py-1.5 text-sm font-medium transition-colors ${
              isMajor ? 'bg-blue-600 text-white' : 'bg-gray-700 text-gray-400 hover:bg-gray-600'
            }`}
          >
            Dur
          </button>
          <button
            onClick={() => onScaleTypeChange(NATURAL_MINOR)}
            className={`px-3 py-1.5 text-sm font-medium transition-colors ${
              !isMajor ? 'bg-blue-600 text-white' : 'bg-gray-700 text-gray-400 hover:bg-gray-600'
            }`}
          >
            Moll
          </button>
        </div>
      </div>

      <div className="flex items-center gap-4">
        {children}
      </div>
    </div>
  );
}
