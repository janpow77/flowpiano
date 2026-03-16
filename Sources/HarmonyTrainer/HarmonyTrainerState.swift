import Foundation

// MARK: - HarmonyTrainerState

public struct HarmonyTrainerState: Equatable, Codable {
    public var isEnabled: Bool
    public var selectedKey: PitchClass
    public var selectedScaleType: ScaleType
    public var detectedChord: Chord?
    public var diatonicAnalysis: DiatonicChord?
    public var diatonicChords: [DiatonicChord]
    public var exercise: ExerciseState
    public var activePitchClasses: Set<Int>

    public init(
        isEnabled: Bool = false,
        selectedKey: PitchClass = .c,
        selectedScaleType: ScaleType = .major
    ) {
        self.isEnabled = isEnabled
        self.selectedKey = selectedKey
        self.selectedScaleType = selectedScaleType
        self.detectedChord = nil
        self.diatonicAnalysis = nil
        self.diatonicChords = []
        self.exercise = ExerciseState()
        self.activePitchClasses = []
    }
}

// MARK: - HarmonyTrainerSettings

public struct HarmonyTrainerSettings: Equatable, Codable {
    public var isEnabled: Bool
    public var selectedKey: PitchClass
    public var selectedScaleType: ScaleType
    public var defaultExerciseMode: ExerciseMode
    public var acceptInversions: Bool

    public init(
        isEnabled: Bool = false,
        selectedKey: PitchClass = .c,
        selectedScaleType: ScaleType = .major,
        defaultExerciseMode: ExerciseMode = .freePlay,
        acceptInversions: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.selectedKey = selectedKey
        self.selectedScaleType = selectedScaleType
        self.defaultExerciseMode = defaultExerciseMode
        self.acceptInversions = acceptInversions
    }
}
