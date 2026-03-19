import type { MidiDevice } from '../../hooks/useMidi.js';

interface MidiStatusProps {
  connected: boolean;
  devices: MidiDevice[];
  error: string | null;
}

export function MidiStatus({ connected, devices, error }: MidiStatusProps) {
  if (error) {
    return <span className="text-red-400 text-xs">{error}</span>;
  }

  if (!connected) {
    return <span className="text-gray-500 text-xs">MIDI: nicht verbunden</span>;
  }

  return (
    <span className="text-emerald-400 text-xs" title={devices.map(d => d.name).join(', ')}>
      MIDI: {devices[0]?.name ?? 'verbunden'}
    </span>
  );
}
