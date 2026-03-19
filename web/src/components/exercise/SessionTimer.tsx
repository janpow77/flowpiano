import type { SessionDuration } from '../../hooks/useSessionTimer.js';

interface SessionTimerProps {
  isActive: boolean;
  remaining: number;
  formatTime: (s: number) => string;
  onStart: (mins: SessionDuration) => void;
  onStop: () => void;
}

const DURATIONS: SessionDuration[] = [3, 5, 10, 20];

export function SessionTimer({ isActive, remaining, formatTime, onStart, onStop }: SessionTimerProps) {
  if (isActive) {
    return (
      <div className="flex items-center gap-2">
        <span className="text-blue-400 font-mono text-sm">⏱ {formatTime(remaining)}</span>
        <button
          onClick={onStop}
          className="text-xs px-2 py-1 bg-gray-700 hover:bg-gray-600 rounded text-gray-300"
        >
          Stop
        </button>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-1">
      {DURATIONS.map(d => (
        <button
          key={d}
          onClick={() => onStart(d)}
          className="text-xs px-2 py-1 bg-gray-700 hover:bg-gray-600 rounded text-gray-400"
        >
          {d}m
        </button>
      ))}
    </div>
  );
}
