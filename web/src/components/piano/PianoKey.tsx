import { useCallback } from 'react';

interface PianoKeyProps {
  note: number;
  isBlack: boolean;
  isActive: boolean;
  isTarget: boolean;
  color: string | null;
  label?: string;
  onMouseDown: (note: number) => void;
  onMouseUp: (note: number) => void;
}

export function PianoKey({ note, isBlack, isActive, isTarget, color, label, onMouseDown, onMouseUp }: PianoKeyProps) {
  const handleDown = useCallback(() => onMouseDown(note), [note, onMouseDown]);
  const handleUp = useCallback(() => onMouseUp(note), [note, onMouseUp]);

  if (isBlack) {
    return (
      <rect
        x={0} y={0}
        width={14} height={62}
        rx={2}
        fill={isActive && color ? color : isActive ? '#888' : '#1a1a2e'}
        stroke={isTarget ? '#fff' : '#333'}
        strokeWidth={isTarget ? 2 : 0.5}
        className="cursor-pointer select-none"
        onMouseDown={handleDown}
        onMouseUp={handleUp}
        onMouseLeave={handleUp}
        onTouchStart={handleDown}
        onTouchEnd={handleUp}
      />
    );
  }

  return (
    <g>
      <rect
        x={0} y={0}
        width={22} height={100}
        rx={2}
        fill={isActive && color ? color : isActive ? '#aaa' : '#f0f0f0'}
        stroke={isTarget ? '#fff' : '#ccc'}
        strokeWidth={isTarget ? 2 : 0.5}
        className="cursor-pointer select-none"
        onMouseDown={handleDown}
        onMouseUp={handleUp}
        onMouseLeave={handleUp}
        onTouchStart={handleDown}
        onTouchEnd={handleUp}
      />
      {label && (
        <text
          x={11} y={90}
          textAnchor="middle"
          fontSize={9}
          fill={isActive && color ? '#fff' : '#666'}
          className="pointer-events-none select-none"
        >
          {label}
        </text>
      )}
    </g>
  );
}
