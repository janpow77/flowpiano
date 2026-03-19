import { useCallback, useEffect, useRef, useState } from 'react';

export interface MidiDevice {
  id: string;
  name: string;
}

export interface MidiEvent {
  note: number;
  velocity: number;
  isNoteOn: boolean;
}

export function useMidi(onMidiEvent: (event: MidiEvent) => void) {
  const [devices, setDevices] = useState<MidiDevice[]>([]);
  const [connected, setConnected] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const callbackRef = useRef(onMidiEvent);
  callbackRef.current = onMidiEvent;

  const handleMidiMessage = useCallback((e: MIDIMessageEvent) => {
    const data = e.data;
    if (!data || data.length < 3) return;

    const status = data[0] & 0xf0;
    const note = data[1];
    const velocity = data[2];

    if (status === 0x90 && velocity > 0) {
      callbackRef.current({ note, velocity, isNoteOn: true });
    } else if (status === 0x80 || (status === 0x90 && velocity === 0)) {
      callbackRef.current({ note, velocity: 0, isNoteOn: false });
    }
  }, []);

  useEffect(() => {
    if (!navigator.requestMIDIAccess) {
      setError('Web MIDI API nicht unterstützt');
      return;
    }

    let inputs: MIDIInput[] = [];

    navigator.requestMIDIAccess().then(access => {
      const updateDevices = () => {
        const devs: MidiDevice[] = [];
        inputs.forEach(input => input.onmidimessage = null);
        inputs = [];

        access.inputs.forEach(input => {
          devs.push({ id: input.id, name: input.name ?? 'Unbekannt' });
          input.onmidimessage = handleMidiMessage;
          inputs.push(input);
        });

        setDevices(devs);
        setConnected(devs.length > 0);
      };

      updateDevices();
      access.onstatechange = updateDevices;
    }).catch(() => {
      setError('MIDI-Zugriff verweigert');
    });

    return () => {
      inputs.forEach(input => { input.onmidimessage = null; });
    };
  }, [handleMidiMessage]);

  return { devices, connected, error };
}
