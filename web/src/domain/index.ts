export { PitchClass, ALL_PITCH_CLASSES, pitchClassFromMidiNote, pitchClassName, pitchClassGermanName, pitchClassFlatName, transposed } from './pitchClass.js';
export { type ScaleType, MAJOR, NATURAL_MINOR, HARMONIC_MINOR } from './scaleType.js';
export { type Scale, scalePitchClasses, scaleContains, scaleDegree } from './scale.js';
export { ChordQuality, chordQualitySymbol, chordQualityGermanName } from './chordQuality.js';
export { type ChordType, CHORD_MAJOR, CHORD_MINOR, CHORD_DIMINISHED, CHORD_AUGMENTED, CHORD_DOMINANT7, CHORD_MAJOR7, CHORD_MINOR7, CHORD_DIMINISHED7, ALL_CHORD_TYPES, chordTypeForQuality } from './chordType.js';
export { Inversion } from './inversion.js';
export { type Chord, createChord, chordPitchClasses, chordDisplayName, chordGermanDisplayName, chordMidiNotes } from './chord.js';
export { detect, detectAll } from './chordDetection.js';
export { HarmonicFunction, harmonicFunctionGermanName, harmonicFunctionAbbreviation } from './harmonicFunction.js';
export { type DiatonicChord } from './diatonicChord.js';
export { diatonicChords, analyze, analyzeByRoot } from './diatonicAnalysis.js';
export { type ProgressionStep } from './progressionStep.js';
export {
  type ProgressionTemplate,
  resolveProgression,
  PACHELBEL, FIFTIES, AXIS_OF_AWESOME, ANDALUSIAN_MAJOR, JAZZ_TWO_FIVE_ONE, BLUES,
  MINOR_CADENCE, ANDALUSIAN_MINOR, MINOR_POP,
  ALL_MAJOR_PROGRESSIONS, ALL_MINOR_PROGRESSIONS, ALL_PROGRESSIONS,
} from './progressionTemplate.js';
export { ExerciseMode, type ExercisePrompt, ExerciseResult, type ExerciseState, createExerciseState, evaluate } from './exercise.js';
export { HarmonyTrainerEngine, type HarmonyTrainerState } from './harmonyTrainerEngine.js';
