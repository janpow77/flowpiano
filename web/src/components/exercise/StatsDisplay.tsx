interface StatsDisplayProps {
  streak: number;
  completedCount: number;
  progressionIndex: number;
  totalSteps: number;
  accuracy: number;
}

export function StatsDisplay({ streak, completedCount, progressionIndex, totalSteps, accuracy }: StatsDisplayProps) {
  return (
    <div className="flex items-center gap-3 text-sm">
      {streak > 0 && (
        <span className="text-orange-400" title="Streak">
          🔥{streak}
        </span>
      )}
      <span className="text-gray-400" title="Abgeschlossen">
        ✓{completedCount}
      </span>
      {totalSteps > 0 && (
        <span className="text-gray-400" title="Fortschritt">
          {progressionIndex + 1}/{totalSteps}
        </span>
      )}
      {completedCount > 0 && (
        <span className="text-gray-400" title="Trefferquote">
          {Math.round(accuracy * 100)}%
        </span>
      )}
    </div>
  );
}
