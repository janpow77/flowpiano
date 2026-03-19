import { useCallback, useEffect, useRef } from 'react';

// QWERTY keyboard mapping: bottom row = white keys, upper row = black keys
// Starting from C3 (MIDI 48)
const KEY_MAP: Record<string, number> = {
  // White keys (bottom row: A-L + ;)
  'a': 48,  // C3
  's': 50,  // D3
  'd': 52,  // E3
  'f': 53,  // F3
  'g': 55,  // G3
  'h': 57,  // A3
  'j': 59,  // B3
  'k': 60,  // C4
  'l': 62,  // D4
  ';': 64,  // E4
  // Black keys (upper row: W-U)
  'w': 49,  // C#3
  'e': 51,  // D#3
  't': 54,  // F#3
  'y': 56,  // G#3
  'u': 58,  // A#3
  'o': 61,  // C#4
  'p': 63,  // D#4
};

interface VirtualPianoCallbacks {
  onNoteOn: (note: number, velocity: number) => void;
  onNoteOff: (note: number) => void;
}

export function useVirtualPiano(callbacks: VirtualPianoCallbacks) {
  const activeKeysRef = useRef(new Set<string>());
  const cbRef = useRef(callbacks);
  cbRef.current = callbacks;

  const handleMouseDown = useCallback((note: number) => {
    cbRef.current.onNoteOn(note, 80);
  }, []);

  const handleMouseUp = useCallback((note: number) => {
    cbRef.current.onNoteOff(note);
  }, []);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.repeat) return;
      const key = e.key.toLowerCase();
      const note = KEY_MAP[key];
      if (note != null && !activeKeysRef.current.has(key)) {
        activeKeysRef.current.add(key);
        cbRef.current.onNoteOn(note, 80);
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      const key = e.key.toLowerCase();
      const note = KEY_MAP[key];
      if (note != null) {
        activeKeysRef.current.delete(key);
        cbRef.current.onNoteOff(note);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, []);

  return { handleMouseDown, handleMouseUp, keyMap: KEY_MAP };
}
