import { useMemo } from 'react';
import { PianoKey } from './PianoKey.js';
import { pitchClassGermanName, pitchClassFromMidiNote, type PitchClass } from '../../domain/pitchClass.js';
import { degreeColor } from '../../utils/degreeColors.js';
import type { DiatonicChord } from '../../domain/diatonicChord.js';

interface PianoKeyboardProps {
  startNote?: number;
  endNote?: number;
  activeNotes: Set<number>;
  targetNotes?: Set<number>;
  diatonicChords: DiatonicChord[];
  onNoteOn: (note: number) => void;
  onNoteOff: (note: number) => void;
}

const BLACK_KEY_OFFSETS: Record<number, number> = {
  1: 15, // C#
  3: 37, // D#
  6: 81, // F#
  8: 103, // G#
  10: 125, // A#
};

const WHITE_KEY_PC = [0, 2, 4, 5, 7, 9, 11]; // C D E F G A B

export function PianoKeyboard({
  startNote = 48,
  endNote = 72,
  activeNotes,
  targetNotes,
  diatonicChords,
  onNoteOn,
  onNoteOff,
}: PianoKeyboardProps) {
  const degreeMap = useMemo(() => {
    const map = new Map<number, number>();
    for (const dc of diatonicChords) {
      map.set(dc.root as number, dc.degree);
    }
    return map;
  }, [diatonicChords]);

  const activePCs = useMemo(() => {
    const set = new Set<number>();
    for (const n of activeNotes) {
      set.add(pitchClassFromMidiNote(n) as number);
    }
    return set;
  }, [activeNotes]);

  const getColor = (note: number): string | null => {
    const pc = pitchClassFromMidiNote(note) as number;
    if (!activePCs.has(pc)) return null;
    const degree = degreeMap.get(pc);
    return degree ? degreeColor(degree) : null;
  };

  // Build white and black keys
  const whiteKeys: { note: number; pc: PitchClass }[] = [];
  const blackKeys: { note: number; pc: PitchClass; whiteIndex: number }[] = [];

  for (let note = startNote; note <= endNote; note++) {
    const pc = pitchClassFromMidiNote(note);
    const pcNum = pc as number;
    if (WHITE_KEY_PC.includes(pcNum)) {
      whiteKeys.push({ note, pc });
    }
  }

  for (let note = startNote; note <= endNote; note++) {
    const pc = pitchClassFromMidiNote(note);
    const pcNum = pc as number;
    if (pcNum in BLACK_KEY_OFFSETS) {
      // Find which white key this black key sits between
      const prevWhitePC = pcNum - 1;
      const whiteIdx = whiteKeys.findIndex(wk => (wk.pc as number) === prevWhitePC && Math.abs(wk.note - note) <= 2);
      if (whiteIdx >= 0) {
        blackKeys.push({ note, pc, whiteIndex: whiteIdx });
      }
    }
  }

  const totalWidth = whiteKeys.length * 23;
  const height = 110;

  return (
    <svg
      viewBox={`0 0 ${totalWidth} ${height}`}
      className="w-full max-w-3xl mx-auto"
      style={{ maxHeight: '160px' }}
    >
      {/* White keys */}
      {whiteKeys.map((wk, i) => (
        <g key={wk.note} transform={`translate(${i * 23}, 0)`}>
          <PianoKey
            note={wk.note}
            isBlack={false}
            isActive={activeNotes.has(wk.note) || activePCs.has(wk.pc as number)}
            isTarget={targetNotes?.has(wk.pc as number) ?? false}
            color={getColor(wk.note)}
            label={pitchClassGermanName(wk.pc)}
            onMouseDown={onNoteOn}
            onMouseUp={onNoteOff}
          />
        </g>
      ))}
      {/* Black keys */}
      {blackKeys.map(bk => (
        <g key={bk.note} transform={`translate(${bk.whiteIndex * 23 + 15}, 0)`}>
          <PianoKey
            note={bk.note}
            isBlack={true}
            isActive={activeNotes.has(bk.note) || activePCs.has(bk.pc as number)}
            isTarget={targetNotes?.has(bk.pc as number) ?? false}
            color={getColor(bk.note)}
            onMouseDown={onNoteOn}
            onMouseUp={onNoteOff}
          />
        </g>
      ))}
    </svg>
  );
}
