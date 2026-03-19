import { ExerciseResult } from '../../domain/exercise.js';

interface ResultBadgeProps {
  result: ExerciseResult;
}

const BADGES: Record<ExerciseResult, { icon: string; label: string; className: string }> = {
  [ExerciseResult.Correct]: { icon: '✓', label: 'Korrekt', className: 'text-emerald-400' },
  [ExerciseResult.Incorrect]: { icon: '✗', label: 'Falsch', className: 'text-red-400' },
  [ExerciseResult.Partial]: { icon: '◐', label: 'Teilweise', className: 'text-yellow-400' },
  [ExerciseResult.Waiting]: { icon: '⏳', label: 'Warte...', className: 'text-gray-500' },
};

export function ResultBadge({ result }: ResultBadgeProps) {
  const badge = BADGES[result];
  return (
    <span className={`text-lg font-bold ${badge.className}`} title={badge.label}>
      {badge.icon} {badge.label}
    </span>
  );
}
