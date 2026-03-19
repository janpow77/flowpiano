import { create } from 'zustand';
import { PitchClass } from '../domain/pitchClass.js';
import type { ScaleType } from '../domain/scaleType.js';
import { MAJOR } from '../domain/scaleType.js';
import { ExerciseMode } from '../domain/exercise.js';
import { HarmonyTrainerEngine, type HarmonyTrainerState } from '../domain/harmonyTrainerEngine.js';
import type { ProgressionTemplate } from '../domain/progressionTemplate.js';

interface HarmonyTrainerStore {
  engine: HarmonyTrainerEngine;
  state: HarmonyTrainerState;

  consume: (note: number, velocity: number, isNoteOn: boolean) => void;
  setKey: (key: PitchClass) => void;
  setScaleType: (scaleType: ScaleType) => void;
  setAcceptInversions: (accept: boolean) => void;
  startExercise: (mode: ExerciseMode, progression?: ProgressionTemplate) => void;
  advanceExercise: () => void;
  resetExercise: () => void;
  reset: () => void;
}

export const useHarmonyTrainer = create<HarmonyTrainerStore>((set, get) => {
  const engine = new HarmonyTrainerEngine(true, PitchClass.C, MAJOR);

  return {
    engine,
    state: engine.state,

    consume: (note, velocity, isNoteOn) => {
      const { engine } = get();
      engine.consume(note, velocity, isNoteOn);
      set({ state: { ...engine.state } });
    },

    setKey: (key) => {
      const { engine } = get();
      engine.setKey(key);
      set({ state: { ...engine.state } });
    },

    setScaleType: (scaleType) => {
      const { engine } = get();
      engine.setScaleType(scaleType);
      set({ state: { ...engine.state } });
    },

    setAcceptInversions: (accept) => {
      const { engine } = get();
      engine.setAcceptInversions(accept);
    },

    startExercise: (mode, progression) => {
      const { engine } = get();
      engine.startExercise(mode, progression);
      set({ state: { ...engine.state } });
    },

    advanceExercise: () => {
      const { engine } = get();
      engine.advanceExercise();
      set({ state: { ...engine.state } });
    },

    resetExercise: () => {
      const { engine } = get();
      engine.resetExercise();
      set({ state: { ...engine.state } });
    },

    reset: () => {
      const { engine } = get();
      engine.reset();
      set({ state: { ...engine.state } });
    },
  };
});
