import { useCallback, useMemo, useState } from 'react';
import { MAJOR } from './domain/scaleType.js';
import { ExerciseMode } from './domain/exercise.js';
import { chordMidiNotes, createChord } from './domain/chord.js';
import type { ProgressionTemplate } from './domain/progressionTemplate.js';

import { useHarmonyTrainer } from './hooks/useHarmonyTrainer.js';
import { useMidi } from './hooks/useMidi.js';
import { useVirtualPiano } from './hooks/useVirtualPiano.js';
import { useAudio } from './hooks/useAudio.js';
import { useSessionTimer, type SessionDuration } from './hooks/useSessionTimer.js';
import { useStats } from './hooks/useStats.js';

import { AppShell } from './components/layout/AppShell.js';
import { HeaderBar } from './components/layout/HeaderBar.js';
import { PianoKeyboard } from './components/piano/PianoKeyboard.js';
import { DiatonicOverview } from './components/harmony/DiatonicOverview.js';
import { ProgressionTimeline } from './components/harmony/ProgressionTimeline.js';
import { ChordDisplay } from './components/harmony/ChordDisplay.js';
import { ChordFeedback } from './components/harmony/ChordFeedback.js';
import { DegreeBar } from './components/harmony/DegreeBar.js';
import { ExerciseModePicker } from './components/exercise/ExerciseModePicker.js';
import { ProgressionSelector } from './components/exercise/ProgressionSelector.js';
import { StatsDisplay } from './components/exercise/StatsDisplay.js';
import { SessionTimer } from './components/exercise/SessionTimer.js';
import { SettingsPanel } from './components/settings/SettingsPanel.js';
import { MidiStatus } from './components/settings/MidiStatus.js';

function App() {
  const trainer = useHarmonyTrainer();
  const { state } = trainer;
  const { playChord, playNote, patch, setPatch, volume, setVolume } = useAudio();
  const { stats, accuracy, recordExercise, updateStreak } = useStats();
  const sessionTimer = useSessionTimer();
  const [acceptInversions, setAcceptInversions] = useState(true);
  const [selectedProgression, setSelectedProgression] = useState<ProgressionTemplate | null>(null);

  const handleNoteOn = useCallback((note: number, velocity: number = 80) => {
    trainer.consume(note, velocity, true);
    playNote(note);
  }, [trainer, playNote]);

  const handleNoteOff = useCallback((note: number) => {
    trainer.consume(note, 0, false);
  }, [trainer]);

  const { devices, connected, error: midiError } = useMidi(
    useCallback((event) => {
      if (event.isNoteOn) {
        handleNoteOn(event.note, event.velocity);
      } else {
        handleNoteOff(event.note);
      }
    }, [handleNoteOn, handleNoteOff])
  );

  const { handleMouseDown, handleMouseUp } = useVirtualPiano({
    onNoteOn: handleNoteOn,
    onNoteOff: handleNoteOff,
  });

  const handleModeSelect = useCallback((mode: ExerciseMode) => {
    if (mode === ExerciseMode.ProgressionGuide && selectedProgression) {
      trainer.startExercise(mode, selectedProgression);
    } else {
      trainer.startExercise(mode);
    }
  }, [trainer, selectedProgression]);

  const handleProgressionSelect = useCallback((template: ProgressionTemplate) => {
    setSelectedProgression(template);
    trainer.startExercise(ExerciseMode.ProgressionGuide, template);
  }, [trainer]);

  const handleAdvance = useCallback(() => {
    recordExercise(true);
    updateStreak(state.exercise.streak);
    trainer.advanceExercise();
  }, [trainer, state.exercise.streak, recordExercise, updateStreak]);

  const handleToggleInversions = useCallback((accept: boolean) => {
    setAcceptInversions(accept);
    trainer.setAcceptInversions(accept);
  }, [trainer]);

  const handleListenChord = useCallback(() => {
    const prompt = state.exercise.currentPrompt;
    if (!prompt || prompt.expectedPitchClasses.size === 0) return;
    const dc = state.diatonicChords.find(d => d.degree === prompt.degree);
    if (dc) {
      const chord = createChord(dc.root, dc.chordType);
      const notes = chordMidiNotes(chord, 4);
      playChord(notes);
    }
  }, [state.exercise.currentPrompt, state.diatonicChords, playChord]);

  const handleResetExercise = useCallback(() => {
    trainer.resetExercise();
  }, [trainer]);

  const handleSessionStart = useCallback((mins: SessionDuration) => {
    sessionTimer.start(mins, state.exercise.completedCount, state.exercise.completedCount);
  }, [sessionTimer, state.exercise.completedCount]);

  const handleSessionStop = useCallback(() => {
    sessionTimer.stop(state.exercise.completedCount, state.exercise.completedCount);
  }, [sessionTimer, state.exercise.completedCount]);

  const isMajor = state.selectedScaleType === MAJOR;
  const scale = useMemo(() => ({
    root: state.selectedKey,
    scaleType: state.selectedScaleType,
  }), [state.selectedKey, state.selectedScaleType]);

  const activeDegree = state.diatonicAnalysis?.degree;

  const targetPCs = useMemo(() => {
    const prompt = state.exercise.currentPrompt;
    if (!prompt) return undefined;
    return new Set(prompt.expectedPitchClasses);
  }, [state.exercise.currentPrompt]);

  return (
    <AppShell>
      {/* Header */}
      <HeaderBar
        selectedKey={state.selectedKey}
        selectedScaleType={state.selectedScaleType}
        onKeyChange={trainer.setKey}
        onScaleTypeChange={trainer.setScaleType}
      >
        <ExerciseModePicker activeMode={state.exercise.mode} onSelectMode={handleModeSelect} />
        <StatsDisplay
          streak={state.exercise.streak}
          completedCount={state.exercise.completedCount}
          progressionIndex={state.exercise.progressionIndex}
          totalSteps={state.exercise.totalSteps}
          accuracy={stats.totalExercises > 0 ? accuracy : 0}
        />
        <SessionTimer
          isActive={sessionTimer.isActive}
          remaining={sessionTimer.remaining}
          formatTime={sessionTimer.formatTime}
          onStart={handleSessionStart}
          onStop={handleSessionStop}
        />
        <button
          onClick={handleResetExercise}
          className="text-gray-400 hover:text-gray-200 text-sm"
          title="Zurücksetzen"
        >
          ↺
        </button>
      </HeaderBar>

      {/* Progression selector */}
      {state.exercise.mode === ExerciseMode.ProgressionGuide && (
        <div className="px-4 py-2 bg-gray-800/50 border-b border-gray-700">
          <ProgressionSelector
            isMajor={isMajor}
            selectedId={selectedProgression?.id ?? null}
            onSelect={handleProgressionSelect}
          />
        </div>
      )}

      {/* Main content */}
      <div className="flex-1 flex flex-col justify-between">
        {/* Diatonic Overview or Progression Timeline */}
        <div>
          {state.exercise.mode === ExerciseMode.ProgressionGuide && state.exercise.progressionTemplate ? (
            <ProgressionTimeline
              template={state.exercise.progressionTemplate}
              scale={scale}
              currentIndex={state.exercise.progressionIndex}
              completedCount={state.exercise.completedCount}
            />
          ) : (
            <DiatonicOverview
              diatonicChords={state.diatonicChords}
              activeDegree={activeDegree}
            />
          )}
        </div>

        {/* Chord Feedback */}
        {state.exercise.mode !== ExerciseMode.FreePlay && (
          <div className="flex items-center gap-2 px-4">
            <div className="flex-1">
              <ChordFeedback
                prompt={state.exercise.currentPrompt}
                result={state.exercise.result}
                onAdvance={handleAdvance}
              />
            </div>
            {state.exercise.currentPrompt && state.exercise.currentPrompt.expectedPitchClasses.size > 0 && (
              <button
                onClick={handleListenChord}
                className="px-3 py-2 bg-gray-700 hover:bg-gray-600 rounded-lg text-sm text-gray-300 transition-colors"
                title="Akkord anhören"
              >
                Anhören
              </button>
            )}
          </div>
        )}

        {/* Chord Display (free play) */}
        {state.exercise.mode === ExerciseMode.FreePlay && (
          <ChordDisplay
            chord={state.detectedChord}
            analysis={state.diatonicAnalysis}
          />
        )}

        {/* Piano Keyboard */}
        <div className="px-4 py-2">
          <PianoKeyboard
            startNote={48}
            endNote={72}
            activeNotes={state.activePitchClasses}
            targetNotes={targetPCs}
            diatonicChords={state.diatonicChords}
            onNoteOn={handleMouseDown}
            onNoteOff={handleMouseUp}
          />
        </div>

        {/* Degree Bar */}
        <DegreeBar
          diatonicChords={state.diatonicChords}
          activeDegree={activeDegree}
        />
      </div>

      {/* Footer / Settings */}
      <div className="flex items-center justify-between px-4 py-2 bg-gray-900 border-t border-gray-700">
        <SettingsPanel
          acceptInversions={acceptInversions}
          onToggleInversions={handleToggleInversions}
          patch={patch}
          onChangePatch={setPatch}
          volume={volume}
          onChangeVolume={setVolume}
        />
        <MidiStatus connected={connected} devices={devices} error={midiError} />
      </div>

      {/* Session Summary Modal */}
      {sessionTimer.summary && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
          <div className="bg-gray-800 rounded-xl p-8 max-w-sm mx-4 text-center">
            <h2 className="text-xl font-bold text-gray-100 mb-4">Session beendet!</h2>
            <div className="space-y-2 text-gray-300">
              <p>Dauer: {sessionTimer.summary.duration} Minuten</p>
              <p>Versuche: {sessionTimer.summary.attempted}</p>
              <p>Korrekt: {sessionTimer.summary.correct}</p>
              <p>Trefferquote: {Math.round(sessionTimer.summary.accuracy * 100)}%</p>
            </div>
            <button
              onClick={() => sessionTimer.setSummary(null)}
              className="mt-6 px-6 py-2 bg-blue-600 hover:bg-blue-500 rounded-lg text-white font-medium"
            >
              OK
            </button>
          </div>
        </div>
      )}
    </AppShell>
  );
}

export default App;
