import XCTest
@testable import HarmonyTrainer
import MIDIEngine

final class HarmonyTrainerTests: XCTestCase {

    // MARK: - Scale Construction

    func testMajorScaleConstruction() {
        let scale = Scale(root: .c, scaleType: .major)
        XCTAssertEqual(scale.pitchClasses, [.c, .d, .e, .f, .g, .a, .b])
    }

    func testMinorScaleConstruction() {
        let scale = Scale(root: .a, scaleType: .naturalMinor)
        XCTAssertEqual(scale.pitchClasses, [.a, .b, .c, .d, .e, .f, .g])
    }

    func testScaleContainsPitchClass() {
        let scale = Scale(root: .c, scaleType: .major)
        XCTAssertTrue(scale.contains(.c))
        XCTAssertTrue(scale.contains(.e))
        XCTAssertFalse(scale.contains(.cSharp))
        XCTAssertFalse(scale.contains(.fSharp))
    }

    func testScaleDegree() {
        let scale = Scale(root: .c, scaleType: .major)
        XCTAssertEqual(scale.degree(of: .c), 1)
        XCTAssertEqual(scale.degree(of: .d), 2)
        XCTAssertEqual(scale.degree(of: .g), 5)
        XCTAssertEqual(scale.degree(of: .b), 7)
        XCTAssertNil(scale.degree(of: .fSharp))
    }

    func testGMajorScale() {
        let scale = Scale(root: .g, scaleType: .major)
        XCTAssertEqual(scale.pitchClasses, [.g, .a, .b, .c, .d, .e, .fSharp])
    }

    // MARK: - Diatonic Chords

    func testDiatonicChordsInCMajor() {
        let scale = Scale(root: .c, scaleType: .major)
        let chords = DiatonicAnalysis.diatonicChords(for: scale)

        XCTAssertEqual(chords.count, 7)

        // I = C major
        XCTAssertEqual(chords[0].root, .c)
        XCTAssertEqual(chords[0].chordType.quality, .major)
        XCTAssertEqual(chords[0].romanNumeral, "I")

        // ii = D minor
        XCTAssertEqual(chords[1].root, .d)
        XCTAssertEqual(chords[1].chordType.quality, .minor)
        XCTAssertEqual(chords[1].romanNumeral, "ii")

        // iii = E minor
        XCTAssertEqual(chords[2].root, .e)
        XCTAssertEqual(chords[2].chordType.quality, .minor)

        // IV = F major
        XCTAssertEqual(chords[3].root, .f)
        XCTAssertEqual(chords[3].chordType.quality, .major)
        XCTAssertEqual(chords[3].romanNumeral, "IV")

        // V = G major
        XCTAssertEqual(chords[4].root, .g)
        XCTAssertEqual(chords[4].chordType.quality, .major)
        XCTAssertEqual(chords[4].romanNumeral, "V")

        // vi = A minor
        XCTAssertEqual(chords[5].root, .a)
        XCTAssertEqual(chords[5].chordType.quality, .minor)
        XCTAssertEqual(chords[5].romanNumeral, "vi")

        // vii° = B diminished
        XCTAssertEqual(chords[6].root, .b)
        XCTAssertEqual(chords[6].chordType.quality, .diminished)
    }

    func testDiatonicChordsInAMinor() {
        let scale = Scale(root: .a, scaleType: .naturalMinor)
        let chords = DiatonicAnalysis.diatonicChords(for: scale)

        XCTAssertEqual(chords.count, 7)
        XCTAssertEqual(chords[0].root, .a)
        XCTAssertEqual(chords[0].chordType.quality, .minor)
        XCTAssertEqual(chords[0].romanNumeral, "i")

        XCTAssertEqual(chords[2].root, .c)
        XCTAssertEqual(chords[2].chordType.quality, .major)
        XCTAssertEqual(chords[2].romanNumeral, "III")
    }

    func testFunctionLabelsForMajorKey() {
        let scale = Scale(root: .c, scaleType: .major)
        let chords = DiatonicAnalysis.diatonicChords(for: scale)

        XCTAssertEqual(chords[0].functionLabel, "T")    // I = Tonika
        XCTAssertEqual(chords[1].functionLabel, "Sp")   // ii = Subdominant-Parallele
        XCTAssertEqual(chords[2].functionLabel, "Dp")   // iii = Dominant-Parallele
        XCTAssertEqual(chords[3].functionLabel, "S")    // IV = Subdominante
        XCTAssertEqual(chords[4].functionLabel, "D")    // V = Dominante
        XCTAssertEqual(chords[5].functionLabel, "Tp")   // vi = Tonika-Parallele
    }

    // MARK: - Chord Detection

    func testDetectCMajorTriad() {
        let chord = ChordDetection.detect(from: [60, 64, 67]) // C E G
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root, .c)
        XCTAssertEqual(chord?.chordType.quality, .major)
        XCTAssertEqual(chord?.inversion, .root)
    }

    func testDetectCMajorFirstInversion() {
        let chord = ChordDetection.detect(from: [64, 67, 72]) // E G C
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root, .c)
        XCTAssertEqual(chord?.chordType.quality, .major)
        XCTAssertEqual(chord?.inversion, .first)
    }

    func testDetectAMinorTriad() {
        let chord = ChordDetection.detect(from: [57, 60, 64]) // A C E
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root, .a)
        XCTAssertEqual(chord?.chordType.quality, .minor)
    }

    func testDetectG7() {
        let chord = ChordDetection.detect(from: [55, 59, 62, 65]) // G B D F
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root, .g)
        XCTAssertEqual(chord?.chordType.quality, .dominant7)
    }

    func testDetectBDiminished() {
        let chord = ChordDetection.detect(from: [59, 62, 65]) // B D F
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root, .b)
        XCTAssertEqual(chord?.chordType.quality, .diminished)
    }

    func testNoChordFromTwoNotes() {
        let chord = ChordDetection.detect(from: [60, 64])
        XCTAssertNil(chord)
    }

    func testNoChordFromEmptyNotes() {
        let chord = ChordDetection.detect(from: [])
        XCTAssertNil(chord)
    }

    func testDetectCMajorAcrossOctaves() {
        // C3 E4 G5 — same pitch classes, different octaves
        let chord = ChordDetection.detect(from: [48, 64, 79])
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root, .c)
        XCTAssertEqual(chord?.chordType.quality, .major)
    }

    // MARK: - Functional Analysis

    func testAnalyzeChordInKey() {
        let scale = Scale(root: .c, scaleType: .major)
        let chord = Chord(root: .f, chordType: .major)
        let analysis = DiatonicAnalysis.analyze(chord: chord, in: scale)

        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis?.degree, 4)
        XCTAssertEqual(analysis?.romanNumeral, "IV")
        XCTAssertEqual(analysis?.harmonicFunction, .subdominant)
    }

    func testAnalyzeNonDiatonicChordReturnsNil() {
        let scale = Scale(root: .c, scaleType: .major)
        let chord = Chord(root: .fSharp, chordType: .major) // F# major not in C major
        let analysis = DiatonicAnalysis.analyze(chord: chord, in: scale)

        XCTAssertNil(analysis)
    }

    // MARK: - Progressions

    func testPachelbelProgressionHas8Steps() {
        XCTAssertEqual(ProgressionTemplate.pachelbel.steps.count, 8)
        XCTAssertEqual(ProgressionTemplate.pachelbel.steps[0].degree, 1)
        XCTAssertEqual(ProgressionTemplate.pachelbel.steps[1].degree, 5)
        XCTAssertEqual(ProgressionTemplate.pachelbel.steps[2].degree, 6)
        XCTAssertEqual(ProgressionTemplate.pachelbel.steps[3].degree, 3)
    }

    func testProgressionResolveInCMajor() {
        let scale = Scale(root: .c, scaleType: .major)
        let resolved = ProgressionTemplate.pachelbel.resolve(in: scale)

        XCTAssertEqual(resolved.count, 8)
        XCTAssertEqual(resolved[0].root, .c)     // I
        XCTAssertEqual(resolved[1].root, .g)     // V
        XCTAssertEqual(resolved[2].root, .a)     // vi
        XCTAssertEqual(resolved[3].root, .e)     // iii
        XCTAssertEqual(resolved[4].root, .f)     // IV
    }

    func testAndalusianMinorWithMajorVOverride() {
        let scale = Scale(root: .a, scaleType: .naturalMinor)
        let resolved = ProgressionTemplate.andalusianMinor.resolve(in: scale)

        XCTAssertEqual(resolved.count, 4)
        // Last step has qualityOverride: .major (harmonic minor V chord)
        XCTAssertEqual(resolved[3].root, .e)
        XCTAssertEqual(resolved[3].chordType.quality, .major)
    }

    // MARK: - Exercise Evaluation

    func testChordPromptCorrect() {
        // Expected: F major = F A C = pitch classes 5, 9, 0
        let prompt = ExercisePrompt(
            instruction: "Play IV in C major",
            expectedPitchClasses: [5, 9, 0],
            acceptInversions: true,
            degree: 4,
            romanNumeral: "IV"
        )

        let result = ExerciseEvaluation.evaluate(
            activePitchClasses: [5, 9, 0],
            prompt: prompt
        )
        XCTAssertEqual(result, .correct)
    }

    func testChordPromptIncorrect() {
        let prompt = ExercisePrompt(
            instruction: "Play IV in C major",
            expectedPitchClasses: [5, 9, 0],
            acceptInversions: true
        )

        // User plays G major (G B D = 7, 11, 2) instead
        let result = ExerciseEvaluation.evaluate(
            activePitchClasses: [7, 11, 2],
            prompt: prompt
        )
        XCTAssertEqual(result, .incorrect)
    }

    func testChordPromptPartial() {
        let prompt = ExercisePrompt(
            instruction: "Play IV in C major",
            expectedPitchClasses: [5, 9, 0],
            acceptInversions: true
        )

        // User plays only F A (2 out of 3)
        let result = ExerciseEvaluation.evaluate(
            activePitchClasses: [5, 9],
            prompt: prompt
        )
        XCTAssertEqual(result, .partial)
    }

    func testChordPromptWaiting() {
        let prompt = ExercisePrompt(
            instruction: "Play IV in C major",
            expectedPitchClasses: [5, 9, 0],
            acceptInversions: true
        )

        let result = ExerciseEvaluation.evaluate(
            activePitchClasses: [],
            prompt: prompt
        )
        XCTAssertEqual(result, .waiting)
    }

    // MARK: - Engine (with MIDIEvent)

    func testConsumeBuildsChordDetection() {
        let trainer = HarmonyTrainer(settings: HarmonyTrainerSettings(isEnabled: true))

        // Play C major chord: C4, E4, G4
        trainer.consume(MIDIEvent(note: 60, velocity: 80, isNoteOn: true))
        trainer.consume(MIDIEvent(note: 64, velocity: 80, isNoteOn: true))
        trainer.consume(MIDIEvent(note: 67, velocity: 80, isNoteOn: true))

        XCTAssertNotNil(trainer.state.detectedChord)
        XCTAssertEqual(trainer.state.detectedChord?.root, .c)
        XCTAssertEqual(trainer.state.detectedChord?.chordType.quality, .major)
    }

    func testNoteOffUpdatesDetection() {
        let trainer = HarmonyTrainer(settings: HarmonyTrainerSettings(isEnabled: true))

        trainer.consume(MIDIEvent(note: 60, velocity: 80, isNoteOn: true))
        trainer.consume(MIDIEvent(note: 64, velocity: 80, isNoteOn: true))
        trainer.consume(MIDIEvent(note: 67, velocity: 80, isNoteOn: true))

        XCTAssertNotNil(trainer.state.detectedChord)

        // Release all notes
        trainer.consume(MIDIEvent(note: 60, velocity: 0, isNoteOn: false))
        trainer.consume(MIDIEvent(note: 64, velocity: 0, isNoteOn: false))
        trainer.consume(MIDIEvent(note: 67, velocity: 0, isNoteOn: false))

        XCTAssertNil(trainer.state.detectedChord)
        XCTAssertTrue(trainer.state.activePitchClasses.isEmpty)
    }

    func testDiatonicAnalysisPopulatedForCMajorChord() {
        let trainer = HarmonyTrainer(settings: HarmonyTrainerSettings(
            isEnabled: true, selectedKey: .c, selectedScaleType: .major
        ))

        // Play C major
        trainer.consume(MIDIEvent(note: 60, velocity: 80, isNoteOn: true))
        trainer.consume(MIDIEvent(note: 64, velocity: 80, isNoteOn: true))
        trainer.consume(MIDIEvent(note: 67, velocity: 80, isNoteOn: true))

        XCTAssertNotNil(trainer.state.diatonicAnalysis)
        XCTAssertEqual(trainer.state.diatonicAnalysis?.romanNumeral, "I")
        XCTAssertEqual(trainer.state.diatonicAnalysis?.harmonicFunction, .tonic)
    }

    func testDisabledTrainerIgnoresEvents() {
        let trainer = HarmonyTrainer(settings: HarmonyTrainerSettings(isEnabled: false))

        trainer.consume(MIDIEvent(note: 60, velocity: 80, isNoteOn: true))
        trainer.consume(MIDIEvent(note: 64, velocity: 80, isNoteOn: true))
        trainer.consume(MIDIEvent(note: 67, velocity: 80, isNoteOn: true))

        XCTAssertNil(trainer.state.detectedChord)
        XCTAssertTrue(trainer.state.activePitchClasses.isEmpty)
    }

    func testKeyChangeRebuildsAnalysis() {
        let trainer = HarmonyTrainer(settings: HarmonyTrainerSettings(
            isEnabled: true, selectedKey: .c
        ))

        XCTAssertEqual(trainer.state.diatonicChords[0].root, .c)

        trainer.setKey(.g)
        XCTAssertEqual(trainer.state.diatonicChords[0].root, .g)
        XCTAssertEqual(trainer.state.diatonicChords[4].root, .d) // V in G major = D
    }

    func testResetClearsAllState() {
        let trainer = HarmonyTrainer(settings: HarmonyTrainerSettings(isEnabled: true))

        trainer.consume(MIDIEvent(note: 60, velocity: 80, isNoteOn: true))
        trainer.consume(MIDIEvent(note: 64, velocity: 80, isNoteOn: true))
        trainer.consume(MIDIEvent(note: 67, velocity: 80, isNoteOn: true))

        trainer.reset()

        XCTAssertNil(trainer.state.detectedChord)
        XCTAssertNil(trainer.state.diatonicAnalysis)
        XCTAssertTrue(trainer.state.activePitchClasses.isEmpty)
    }

    func testProgressionExerciseGeneratesPrompts() {
        let trainer = HarmonyTrainer(settings: HarmonyTrainerSettings(
            isEnabled: true, selectedKey: .c, selectedScaleType: .major
        ))

        trainer.startExercise(mode: .progressionGuide, progression: .pachelbel)

        XCTAssertEqual(trainer.state.exercise.mode, .progressionGuide)
        XCTAssertEqual(trainer.state.exercise.totalSteps, 8)
        XCTAssertEqual(trainer.state.exercise.progressionIndex, 0)
        XCTAssertNotNil(trainer.state.exercise.currentPrompt)
        // First step is I (C major), expected pitch classes: C=0, E=4, G=7
        XCTAssertEqual(trainer.state.exercise.currentPrompt?.expectedPitchClasses, [0, 4, 7])
    }

    func testChordPromptExerciseEvaluatesCorrectly() {
        let trainer = HarmonyTrainer(settings: HarmonyTrainerSettings(
            isEnabled: true, selectedKey: .c, selectedScaleType: .major
        ))

        trainer.startExercise(mode: .progressionGuide, progression: .pachelbel)

        // Play C major (I)
        trainer.consume(MIDIEvent(note: 60, velocity: 80, isNoteOn: true))
        trainer.consume(MIDIEvent(note: 64, velocity: 80, isNoteOn: true))
        trainer.consume(MIDIEvent(note: 67, velocity: 80, isNoteOn: true))

        XCTAssertEqual(trainer.state.exercise.result, .correct)
        XCTAssertEqual(trainer.state.exercise.completedCount, 1)
        XCTAssertEqual(trainer.state.exercise.streak, 1)
    }

    func testChordDisplayName() {
        let cMajor = Chord(root: .c, chordType: .major)
        XCTAssertEqual(cMajor.displayName, "C")

        let aMinor = Chord(root: .a, chordType: .minor)
        XCTAssertEqual(aMinor.displayName, "Am")

        let g7 = Chord(root: .g, chordType: .dominant7)
        XCTAssertEqual(g7.displayName, "G7")

        let bDim = Chord(root: .b, chordType: .diminished)
        XCTAssertEqual(bDim.displayName, "B\u{00B0}")
    }

    func testPitchClassFromMidiNote() {
        XCTAssertEqual(PitchClass(midiNote: 60), .c)   // C4
        XCTAssertEqual(PitchClass(midiNote: 69), .a)   // A4
        XCTAssertEqual(PitchClass(midiNote: 72), .c)   // C5
        XCTAssertEqual(PitchClass(midiNote: 61), .cSharp)
    }

    func testChordMidiNotes() {
        let cMajor = Chord(root: .c, chordType: .major)
        let notes = cMajor.midiNotes(octave: 3)
        XCTAssertEqual(notes, [48, 52, 55]) // C3, E3, G3

        let cMajorFirst = Chord(root: .c, chordType: .major, inversion: .first)
        let firstNotes = cMajorFirst.midiNotes(octave: 3)
        XCTAssertEqual(firstNotes, [52, 55, 60]) // E3, G3, C4
    }

    func testStateIsCodable() throws {
        let state = HarmonyTrainerState(isEnabled: true, selectedKey: .g, selectedScaleType: .major)
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(HarmonyTrainerState.self, from: data)
        XCTAssertEqual(state, decoded)
    }
}
