import { ExerciseResult, type ExercisePrompt } from '../../domain/exercise.js';
import { ResultBadge } from '../exercise/ResultBadge.js';

interface ChordFeedbackProps {
  prompt: ExercisePrompt | null;
  result: ExerciseResult;
  onAdvance: () => void;
}

export function ChordFeedback({ prompt, result, onAdvance }: ChordFeedbackProps) {
  if (!prompt) return null;

  return (
    <div className="flex items-center justify-between px-6 py-3 bg-gray-800/50 rounded-lg mx-4">
      <div className="flex-1">
        <div className="text-lg text-gray-200">{prompt.instruction}</div>
      </div>
      <div className="flex items-center gap-4">
        <ResultBadge result={result} />
        {result === ExerciseResult.Correct && (
          <button
            onClick={onAdvance}
            className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg text-white text-sm font-medium transition-colors"
          >
            Weiter →
          </button>
        )}
      </div>
    </div>
  );
}
