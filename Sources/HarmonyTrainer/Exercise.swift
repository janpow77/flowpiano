import Foundation

// MARK: - ExerciseMode

public enum ExerciseMode: String, Codable, Equatable, Hashable {
    case freePlay              // Detect and label what the user plays
    case chordPrompt           // "Play the IV chord in C major"
    case progressionGuide      // Step through a progression
    case scalePractice         // Play a scale with degree feedback
}

// MARK: - ExercisePrompt

public struct ExercisePrompt: Equatable, Codable, Hashable {
    public let instruction: String
    public let expectedPitchClasses: Set<Int>
    public let acceptInversions: Bool
    public let degree: Int?
    public let romanNumeral: String?

    public init(
        instruction: String,
        expectedPitchClasses: Set<Int>,
        acceptInversions: Bool = true,
        degree: Int? = nil,
        romanNumeral: String? = nil
    ) {
        self.instruction = instruction
        self.expectedPitchClasses = expectedPitchClasses
        self.acceptInversions = acceptInversions
        self.degree = degree
        self.romanNumeral = romanNumeral
    }
}

// MARK: - ExerciseResult

public enum ExerciseResult: String, Codable, Equatable, Hashable {
    case correct
    case incorrect
    case partial        // Some notes right, not all
    case waiting        // Not enough notes yet
}

// MARK: - ExerciseState

public struct ExerciseState: Equatable, Codable, Hashable {
    public var mode: ExerciseMode
    public var currentPrompt: ExercisePrompt?
    public var result: ExerciseResult
    public var progressionTemplate: ProgressionTemplate?
    public var progressionIndex: Int
    public var totalSteps: Int
    public var completedCount: Int
    public var streak: Int

    public init(mode: ExerciseMode = .freePlay) {
        self.mode = mode
        self.currentPrompt = nil
        self.result = .waiting
        self.progressionTemplate = nil
        self.progressionIndex = 0
        self.totalSteps = 0
        self.completedCount = 0
        self.streak = 0
    }
}

// MARK: - Exercise Evaluation

public enum ExerciseEvaluation {
    /// Evaluate active pitch classes against an exercise prompt.
    public static func evaluate(
        activePitchClasses: Set<Int>,
        prompt: ExercisePrompt
    ) -> ExerciseResult {
        guard !prompt.expectedPitchClasses.isEmpty else { return .waiting }

        if activePitchClasses.isEmpty {
            return .waiting
        }

        if prompt.acceptInversions {
            // Match pitch classes regardless of octave/inversion
            if activePitchClasses == prompt.expectedPitchClasses {
                return .correct
            }
            if activePitchClasses.isSubset(of: prompt.expectedPitchClasses) && activePitchClasses.count >= 2 {
                return .partial
            }
            if activePitchClasses.count >= prompt.expectedPitchClasses.count {
                return .incorrect
            }
            return .waiting
        } else {
            // Strict: exact match required
            if activePitchClasses == prompt.expectedPitchClasses {
                return .correct
            }
            if activePitchClasses.isSubset(of: prompt.expectedPitchClasses) {
                return .partial
            }
            return .incorrect
        }
    }
}
