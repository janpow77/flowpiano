import { type PitchClass, pitchClassGermanName } from './pitchClass.js';
import type { ScaleType } from './scaleType.js';
import { MAJOR } from './scaleType.js';
import { type Scale, scalePitchClasses } from './scale.js';
import { chordQualitySymbol } from './chordQuality.js';
import type { Chord } from './chord.js';
import { createChord, chordPitchClasses } from './chord.js';
import { detect } from './chordDetection.js';
import type { DiatonicChord } from './diatonicChord.js';
import { diatonicChords, analyze } from './diatonicAnalysis.js';
import type { ProgressionTemplate } from './progressionTemplate.js';
import { resolveProgression } from './progressionTemplate.js';
import {
  ExerciseMode,
  type ExercisePrompt,
  ExerciseResult,
  type ExerciseState,
  createExerciseState,
  evaluate,
} from './exercise.js';

export interface HarmonyTrainerState {
  isEnabled: boolean;
  selectedKey: PitchClass;
  selectedScaleType: ScaleType;
  detectedChord: Chord | null;
  diatonicAnalysis: DiatonicChord | null;
  diatonicChords: DiatonicChord[];
  exercise: ExerciseState;
  activePitchClasses: Set<number>;
}

export class HarmonyTrainerEngine {
  state: HarmonyTrainerState;
  private activeNotes: Map<number, number> = new Map();
  private acceptInversions: boolean;

  constructor(
    isEnabled: boolean = false,
    selectedKey: PitchClass = 0, // C
    selectedScaleType: ScaleType = MAJOR,
    acceptInversions: boolean = true,
  ) {
    this.acceptInversions = acceptInversions;
    this.state = {
      isEnabled,
      selectedKey,
      selectedScaleType,
      detectedChord: null,
      diatonicAnalysis: null,
      diatonicChords: [],
      exercise: createExerciseState(),
      activePitchClasses: new Set(),
    };
    this.rebuildDiatonicChords();
  }

  setEnabled(enabled: boolean): void {
    this.state.isEnabled = enabled;
    if (!enabled) this.reset();
  }

  setKey(key: PitchClass): void {
    this.state.selectedKey = key;
    this.rebuildDiatonicChords();
    this.resetExercise();
  }

  setScaleType(scaleType: ScaleType): void {
    this.state.selectedScaleType = scaleType;
    this.rebuildDiatonicChords();
    this.resetExercise();
  }

  setAcceptInversions(accept: boolean): void {
    this.acceptInversions = accept;
  }

  consume(note: number, velocity: number, isNoteOn: boolean): void {
    if (!this.state.isEnabled) return;

    if (isNoteOn && velocity > 0) {
      this.activeNotes.set(note, velocity);
    } else {
      this.activeNotes.delete(note);
    }

    const midiNotes = [...this.activeNotes.keys()];
    this.state.activePitchClasses = new Set(midiNotes.map(n => (((n % 12) + 12) % 12)));

    this.state.detectedChord = detect(midiNotes);

    const scale: Scale = { root: this.state.selectedKey, scaleType: this.state.selectedScaleType };
    this.state.diatonicAnalysis = this.state.detectedChord
      ? analyze(this.state.detectedChord, scale)
      : null;

    this.evaluateExercise();
  }

  startExercise(mode: ExerciseMode, progression?: ProgressionTemplate): void {
    this.state.exercise = createExerciseState(mode);

    switch (mode) {
      case ExerciseMode.FreePlay:
        break;
      case ExerciseMode.ChordPrompt:
        this.state.exercise.currentPrompt = this.generateRandomChordPrompt();
        break;
      case ExerciseMode.ProgressionGuide:
        if (progression) {
          this.state.exercise.progressionTemplate = progression;
          this.state.exercise.totalSteps = progression.steps.length;
          this.state.exercise.progressionIndex = 0;
          this.state.exercise.currentPrompt = this.generateProgressionPrompt(0, progression);
        }
        break;
      case ExerciseMode.ScalePractice:
        this.state.exercise.currentPrompt = this.generateScalePrompt(1);
        this.state.exercise.totalSteps = 7;
        this.state.exercise.progressionIndex = 0;
        break;
    }
  }

  advanceExercise(): void {
    switch (this.state.exercise.mode) {
      case ExerciseMode.FreePlay:
        break;
      case ExerciseMode.ChordPrompt:
        this.state.exercise.result = ExerciseResult.Waiting;
        this.state.exercise.currentPrompt = this.generateRandomChordPrompt();
        break;
      case ExerciseMode.ProgressionGuide: {
        const nextIndex = this.state.exercise.progressionIndex + 1;
        const prog = this.state.exercise.progressionTemplate;
        if (prog && nextIndex < prog.steps.length) {
          this.state.exercise.progressionIndex = nextIndex;
          this.state.exercise.result = ExerciseResult.Waiting;
          this.state.exercise.currentPrompt = this.generateProgressionPrompt(nextIndex, prog);
        } else {
          this.state.exercise.result = ExerciseResult.Correct;
          this.state.exercise.currentPrompt = null;
        }
        break;
      }
      case ExerciseMode.ScalePractice: {
        const nextDegree = this.state.exercise.progressionIndex + 2;
        if (nextDegree <= 7) {
          this.state.exercise.progressionIndex += 1;
          this.state.exercise.result = ExerciseResult.Waiting;
          this.state.exercise.currentPrompt = this.generateScalePrompt(nextDegree);
        } else {
          this.state.exercise.result = ExerciseResult.Correct;
          this.state.exercise.currentPrompt = null;
        }
        break;
      }
    }
  }

  resetExercise(): void {
    const mode = this.state.exercise.mode;
    const prog = this.state.exercise.progressionTemplate ?? undefined;
    this.startExercise(mode, prog);
  }

  reset(): void {
    this.activeNotes.clear();
    this.state.activePitchClasses = new Set();
    this.state.detectedChord = null;
    this.state.diatonicAnalysis = null;
    this.state.exercise = createExerciseState();
  }

  private rebuildDiatonicChords(): void {
    const scale: Scale = { root: this.state.selectedKey, scaleType: this.state.selectedScaleType };
    this.state.diatonicChords = diatonicChords(scale);
  }

  private evaluateExercise(): void {
    const prompt = this.state.exercise.currentPrompt;
    if (!prompt) return;

    const result = evaluate(this.state.activePitchClasses, prompt);
    this.state.exercise.result = result;

    if (result === ExerciseResult.Correct) {
      this.state.exercise.completedCount += 1;
      this.state.exercise.streak += 1;
    } else if (result === ExerciseResult.Incorrect) {
      this.state.exercise.streak = 0;
    }
  }

  private generateRandomChordPrompt(): ExercisePrompt {
    const dc = this.state.diatonicChords;
    if (dc.length === 0) {
      return { instruction: 'Keine Akkorde verfügbar', expectedPitchClasses: new Set(), acceptInversions: true };
    }

    const randomIndex = Math.floor(Math.random() * dc.length);
    const d = dc[randomIndex];
    const chord = createChord(d.root, d.chordType);
    const expectedPC = new Set(chordPitchClasses(chord).map(pc => pc as number));
    const scaleName = this.state.selectedScaleType === MAJOR ? 'Dur' : 'Moll';

    return {
      instruction: `Spiele ${d.romanNumeral} in ${pitchClassGermanName(this.state.selectedKey)}-${scaleName}`,
      expectedPitchClasses: expectedPC,
      acceptInversions: this.acceptInversions,
      degree: d.degree,
      romanNumeral: d.romanNumeral,
    };
  }

  private generateProgressionPrompt(index: number, template: ProgressionTemplate): ExercisePrompt {
    const scale: Scale = { root: this.state.selectedKey, scaleType: this.state.selectedScaleType };
    const resolved = resolveProgression(template, scale);
    if (index >= resolved.length) {
      return { instruction: 'Progression abgeschlossen!', expectedPitchClasses: new Set(), acceptInversions: true };
    }

    const dc = resolved[index];
    const chord = createChord(dc.root, dc.chordType);
    const expectedPC = new Set(chordPitchClasses(chord).map(pc => pc as number));

    return {
      instruction: `Schritt ${index + 1}/${resolved.length}: ${dc.romanNumeral} (${pitchClassGermanName(dc.root)}${chordQualitySymbol(dc.chordType.quality)})`,
      expectedPitchClasses: expectedPC,
      acceptInversions: this.acceptInversions,
      degree: dc.degree,
      romanNumeral: dc.romanNumeral,
    };
  }

  private generateScalePrompt(degree: number): ExercisePrompt {
    const scale: Scale = { root: this.state.selectedKey, scaleType: this.state.selectedScaleType };
    const pcs = scalePitchClasses(scale);
    if (degree < 1 || degree > pcs.length) {
      return { instruction: 'Tonleiter abgeschlossen!', expectedPitchClasses: new Set(), acceptInversions: false };
    }

    const pc = pcs[degree - 1];
    const scaleName = this.state.selectedScaleType === MAJOR ? 'Dur' : 'Moll';

    return {
      instruction: `Spiele Stufe ${degree} der ${pitchClassGermanName(this.state.selectedKey)}-${scaleName}-Tonleiter (${pitchClassGermanName(pc)})`,
      expectedPitchClasses: new Set([pc as number]),
      acceptInversions: false,
      degree,
      romanNumeral: `${degree}`,
    };
  }
}
