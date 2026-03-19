import type { ProgressionTemplate } from './progressionTemplate.js';

export enum ExerciseMode {
  FreePlay = 'freePlay',
  ChordPrompt = 'chordPrompt',
  ProgressionGuide = 'progressionGuide',
  ScalePractice = 'scalePractice',
}

export interface ExercisePrompt {
  readonly instruction: string;
  readonly expectedPitchClasses: ReadonlySet<number>;
  readonly acceptInversions: boolean;
  readonly degree?: number;
  readonly romanNumeral?: string;
}

export enum ExerciseResult {
  Correct = 'correct',
  Incorrect = 'incorrect',
  Partial = 'partial',
  Waiting = 'waiting',
}

export interface ExerciseState {
  mode: ExerciseMode;
  currentPrompt: ExercisePrompt | null;
  result: ExerciseResult;
  progressionTemplate: ProgressionTemplate | null;
  progressionIndex: number;
  totalSteps: number;
  completedCount: number;
  streak: number;
}

export function createExerciseState(mode: ExerciseMode = ExerciseMode.FreePlay): ExerciseState {
  return {
    mode,
    currentPrompt: null,
    result: ExerciseResult.Waiting,
    progressionTemplate: null,
    progressionIndex: 0,
    totalSteps: 0,
    completedCount: 0,
    streak: 0,
  };
}

export function evaluate(
  activePitchClasses: ReadonlySet<number>,
  prompt: ExercisePrompt,
): ExerciseResult {
  if (prompt.expectedPitchClasses.size === 0) return ExerciseResult.Waiting;
  if (activePitchClasses.size === 0) return ExerciseResult.Waiting;

  if (prompt.acceptInversions) {
    if (setsEqual(activePitchClasses, prompt.expectedPitchClasses)) {
      return ExerciseResult.Correct;
    }
    if (isSubset(activePitchClasses, prompt.expectedPitchClasses) && activePitchClasses.size >= 2) {
      return ExerciseResult.Partial;
    }
    if (activePitchClasses.size >= prompt.expectedPitchClasses.size) {
      return ExerciseResult.Incorrect;
    }
    return ExerciseResult.Waiting;
  } else {
    if (setsEqual(activePitchClasses, prompt.expectedPitchClasses)) {
      return ExerciseResult.Correct;
    }
    if (isSubset(activePitchClasses, prompt.expectedPitchClasses)) {
      return ExerciseResult.Partial;
    }
    return ExerciseResult.Incorrect;
  }
}

function setsEqual(a: ReadonlySet<number>, b: ReadonlySet<number>): boolean {
  if (a.size !== b.size) return false;
  for (const v of a) {
    if (!b.has(v)) return false;
  }
  return true;
}

function isSubset(sub: ReadonlySet<number>, sup: ReadonlySet<number>): boolean {
  for (const v of sub) {
    if (!sup.has(v)) return false;
  }
  return true;
}
