import { ExerciseMode } from '../../domain/exercise.js';

interface ExerciseModePickerProps {
  activeMode: ExerciseMode;
  onSelectMode: (mode: ExerciseMode) => void;
}

const MODES: { mode: ExerciseMode; label: string }[] = [
  { mode: ExerciseMode.FreePlay, label: 'Frei' },
  { mode: ExerciseMode.ChordPrompt, label: 'Akkord' },
  { mode: ExerciseMode.ProgressionGuide, label: 'Progression' },
  { mode: ExerciseMode.ScalePractice, label: 'Tonleiter' },
];

export function ExerciseModePicker({ activeMode, onSelectMode }: ExerciseModePickerProps) {
  return (
    <div className="flex gap-1">
      {MODES.map(({ mode, label }) => (
        <button
          key={mode}
          onClick={() => onSelectMode(mode)}
          className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
            activeMode === mode
              ? 'bg-blue-600 text-white'
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          {label}
        </button>
      ))}
    </div>
  );
}
