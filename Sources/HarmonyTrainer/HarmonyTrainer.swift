import Foundation
import MIDIEngine

public final class HarmonyTrainer {
    public private(set) var state: HarmonyTrainerState
    private var activeNotes: [Int: Int] = [:]  // midiNote -> velocity
    private var acceptInversions: Bool

    public init(settings: HarmonyTrainerSettings = HarmonyTrainerSettings()) {
        self.acceptInversions = settings.acceptInversions
        self.state = HarmonyTrainerState(
            isEnabled: settings.isEnabled,
            selectedKey: settings.selectedKey,
            selectedScaleType: settings.selectedScaleType
        )
        rebuildDiatonicChords()
    }

    // MARK: - Configuration

    public func setEnabled(_ enabled: Bool) {
        state.isEnabled = enabled
        if !enabled { reset() }
    }

    public func setKey(_ key: PitchClass) {
        state.selectedKey = key
        rebuildDiatonicChords()
        resetExercise()
    }

    public func setScaleType(_ scaleType: ScaleType) {
        state.selectedScaleType = scaleType
        rebuildDiatonicChords()
        resetExercise()
    }

    public func setAcceptInversions(_ accept: Bool) {
        acceptInversions = accept
    }

    // MARK: - MIDI Consumption

    public func consume(_ event: MIDIEvent) {
        guard state.isEnabled else { return }

        if event.isNoteOn && event.velocity > 0 {
            activeNotes[event.note] = event.velocity
        } else {
            activeNotes.removeValue(forKey: event.note)
        }

        let midiNotes = Array(activeNotes.keys)
        state.activePitchClasses = Set(midiNotes.map { (($0 % 12) + 12) % 12 })

        // Chord detection
        state.detectedChord = ChordDetection.detect(from: midiNotes)

        // Functional analysis
        let scale = Scale(root: state.selectedKey, scaleType: state.selectedScaleType)
        state.diatonicAnalysis = state.detectedChord.flatMap {
            DiatonicAnalysis.analyze(chord: $0, in: scale)
        }

        // Exercise evaluation
        evaluateExercise()
    }

    // MARK: - Exercise Control

    public func startExercise(mode: ExerciseMode, progression: ProgressionTemplate? = nil) {
        state.exercise = ExerciseState(mode: mode)

        switch mode {
        case .freePlay:
            break

        case .chordPrompt:
            state.exercise.currentPrompt = generateRandomChordPrompt()

        case .progressionGuide:
            if let prog = progression {
                state.exercise.progressionTemplate = prog
                state.exercise.totalSteps = prog.steps.count
                state.exercise.progressionIndex = 0
                state.exercise.currentPrompt = generateProgressionPrompt(at: 0, template: prog)
            }

        case .scalePractice:
            state.exercise.currentPrompt = generateScalePrompt(degree: 1)
            state.exercise.totalSteps = 7
            state.exercise.progressionIndex = 0
        }
    }

    public func advanceExercise() {
        switch state.exercise.mode {
        case .freePlay:
            break

        case .chordPrompt:
            state.exercise.result = .waiting
            state.exercise.currentPrompt = generateRandomChordPrompt()

        case .progressionGuide:
            let nextIndex = state.exercise.progressionIndex + 1
            if let prog = state.exercise.progressionTemplate, nextIndex < prog.steps.count {
                state.exercise.progressionIndex = nextIndex
                state.exercise.result = .waiting
                state.exercise.currentPrompt = generateProgressionPrompt(at: nextIndex, template: prog)
            } else {
                // Progression complete
                state.exercise.result = .correct
                state.exercise.currentPrompt = nil
            }

        case .scalePractice:
            let nextDegree = state.exercise.progressionIndex + 2  // 1-based
            if nextDegree <= 7 {
                state.exercise.progressionIndex += 1
                state.exercise.result = .waiting
                state.exercise.currentPrompt = generateScalePrompt(degree: nextDegree)
            } else {
                state.exercise.result = .correct
                state.exercise.currentPrompt = nil
            }
        }
    }

    public func resetExercise() {
        let mode = state.exercise.mode
        let prog = state.exercise.progressionTemplate
        startExercise(mode: mode, progression: prog)
    }

    public func reset() {
        activeNotes = [:]
        state.activePitchClasses = []
        state.detectedChord = nil
        state.diatonicAnalysis = nil
        state.exercise = ExerciseState()
    }

    // MARK: - Private

    private func rebuildDiatonicChords() {
        let scale = Scale(root: state.selectedKey, scaleType: state.selectedScaleType)
        state.diatonicChords = DiatonicAnalysis.diatonicChords(for: scale)
    }

    private func evaluateExercise() {
        guard let prompt = state.exercise.currentPrompt else { return }

        let result = ExerciseEvaluation.evaluate(
            activePitchClasses: state.activePitchClasses,
            prompt: prompt
        )
        state.exercise.result = result

        if result == .correct {
            state.exercise.completedCount += 1
            state.exercise.streak += 1

            // Auto-advance for progression guide
            if state.exercise.mode == .progressionGuide || state.exercise.mode == .scalePractice {
                // Don't auto-advance — let the UI or coordinator call advanceExercise()
                // after showing feedback
            }
        } else if result == .incorrect {
            state.exercise.streak = 0
        }
    }

    private func generateRandomChordPrompt() -> ExercisePrompt {
        let diatonic = state.diatonicChords
        guard !diatonic.isEmpty else {
            return ExercisePrompt(instruction: "Keine Akkorde verfügbar", expectedPitchClasses: [])
        }

        let randomIndex = Int.random(in: 0..<diatonic.count)
        let dc = diatonic[randomIndex]
        let chord = Chord(root: dc.root, chordType: dc.chordType)
        let expectedPC = Set(chord.pitchClasses.map(\.rawValue))
        let scaleName = state.selectedScaleType == .major ? "Dur" : "Moll"

        return ExercisePrompt(
            instruction: "Spiele \(dc.romanNumeral) in \(state.selectedKey.germanName)-\(scaleName)",
            expectedPitchClasses: expectedPC,
            acceptInversions: acceptInversions,
            degree: dc.degree,
            romanNumeral: dc.romanNumeral
        )
    }

    private func generateProgressionPrompt(at index: Int, template: ProgressionTemplate) -> ExercisePrompt {
        let scale = Scale(root: state.selectedKey, scaleType: state.selectedScaleType)
        let resolved = template.resolve(in: scale)
        guard index < resolved.count else {
            return ExercisePrompt(instruction: "Progression abgeschlossen!", expectedPitchClasses: [])
        }

        let dc = resolved[index]
        let chord = Chord(root: dc.root, chordType: dc.chordType)
        let expectedPC = Set(chord.pitchClasses.map(\.rawValue))

        return ExercisePrompt(
            instruction: "Schritt \(index + 1)/\(resolved.count): \(dc.romanNumeral) (\(dc.root.germanName)\(dc.chordType.quality.symbol))",
            expectedPitchClasses: expectedPC,
            acceptInversions: acceptInversions,
            degree: dc.degree,
            romanNumeral: dc.romanNumeral
        )
    }

    private func generateScalePrompt(degree: Int) -> ExercisePrompt {
        let scale = Scale(root: state.selectedKey, scaleType: state.selectedScaleType)
        let pcs = scale.pitchClasses
        guard degree >= 1, degree <= pcs.count else {
            return ExercisePrompt(instruction: "Tonleiter abgeschlossen!", expectedPitchClasses: [])
        }

        let pc = pcs[degree - 1]
        let scaleName = state.selectedScaleType == .major ? "Dur" : "Moll"

        return ExercisePrompt(
            instruction: "Spiele Stufe \(degree) der \(state.selectedKey.germanName)-\(scaleName)-Tonleiter (\(pc.germanName))",
            expectedPitchClasses: [pc.rawValue],
            acceptInversions: false,
            degree: degree,
            romanNumeral: "\(degree)"
        )
    }
}
