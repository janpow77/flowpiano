import { describe, it, expect } from 'vitest';
import { ExerciseResult, evaluate, type ExercisePrompt } from '../../domain/exercise.js';

describe('Exercise Evaluation', () => {
  const fMajorPrompt: ExercisePrompt = {
    instruction: 'Play IV in C major',
    expectedPitchClasses: new Set([5, 9, 0]),  // F A C
    acceptInversions: true,
    degree: 4,
    romanNumeral: 'IV',
  };

  it('evaluates correct chord', () => {
    const result = evaluate(new Set([5, 9, 0]), fMajorPrompt);
    expect(result).toBe(ExerciseResult.Correct);
  });

  it('evaluates incorrect chord', () => {
    // User plays G major (G B D = 7, 11, 2) instead
    const result = evaluate(new Set([7, 11, 2]), fMajorPrompt);
    expect(result).toBe(ExerciseResult.Incorrect);
  });

  it('evaluates partial chord', () => {
    // User plays only F A (2 out of 3)
    const result = evaluate(new Set([5, 9]), fMajorPrompt);
    expect(result).toBe(ExerciseResult.Partial);
  });

  it('evaluates waiting when no notes', () => {
    const result = evaluate(new Set(), fMajorPrompt);
    expect(result).toBe(ExerciseResult.Waiting);
  });

  it('evaluates waiting with single correct note (acceptInversions)', () => {
    const result = evaluate(new Set([5]), fMajorPrompt);
    expect(result).toBe(ExerciseResult.Waiting);
  });
});
