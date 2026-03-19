import type { SoundPatch } from '../../hooks/useAudio.js';

interface SettingsPanelProps {
  acceptInversions: boolean;
  onToggleInversions: (v: boolean) => void;
  patch: SoundPatch;
  onChangePatch: (p: SoundPatch) => void;
  volume: number;
  onChangeVolume: (v: number) => void;
}

const PATCHES: { value: SoundPatch; label: string }[] = [
  { value: 'piano', label: 'Piano' },
  { value: 'epiano', label: 'E-Piano' },
  { value: 'pad', label: 'Pad' },
];

export function SettingsPanel({
  acceptInversions, onToggleInversions,
  patch, onChangePatch,
  volume, onChangeVolume,
}: SettingsPanelProps) {
  return (
    <div className="flex items-center gap-4 text-sm">
      <label className="flex items-center gap-1.5 text-gray-400 cursor-pointer">
        <input
          type="checkbox"
          checked={acceptInversions}
          onChange={e => onToggleInversions(e.target.checked)}
          className="rounded"
        />
        Umkehrungen
      </label>

      <select
        value={patch}
        onChange={e => onChangePatch(e.target.value as SoundPatch)}
        className="bg-gray-700 text-gray-300 rounded px-2 py-1 text-xs border border-gray-600"
      >
        {PATCHES.map(p => (
          <option key={p.value} value={p.value}>{p.label}</option>
        ))}
      </select>

      <input
        type="range"
        min={0}
        max={1}
        step={0.05}
        value={volume}
        onChange={e => onChangeVolume(parseFloat(e.target.value))}
        className="w-16"
        title={`Lautstärke: ${Math.round(volume * 100)}%`}
      />
    </div>
  );
}
