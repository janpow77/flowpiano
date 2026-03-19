import type { ProgressionTemplate } from '../../domain/progressionTemplate.js';
import {
  ALL_MAJOR_PROGRESSIONS,
  ALL_MINOR_PROGRESSIONS,
} from '../../domain/progressionTemplate.js';

interface ProgressionSelectorProps {
  isMajor: boolean;
  selectedId: string | null;
  onSelect: (template: ProgressionTemplate) => void;
}

export function ProgressionSelector({ isMajor, selectedId, onSelect }: ProgressionSelectorProps) {
  const progressions = isMajor ? ALL_MAJOR_PROGRESSIONS : ALL_MINOR_PROGRESSIONS;

  return (
    <select
      value={selectedId ?? ''}
      onChange={e => {
        const p = progressions.find(p => p.id === e.target.value);
        if (p) onSelect(p);
      }}
      className="bg-gray-700 text-gray-200 rounded-lg px-3 py-1.5 text-sm border border-gray-600 focus:outline-none focus:border-blue-500"
    >
      <option value="" disabled>Progression wählen...</option>
      {progressions.map(p => (
        <option key={p.id} value={p.id}>
          {p.name} — {p.description}
        </option>
      ))}
    </select>
  );
}
