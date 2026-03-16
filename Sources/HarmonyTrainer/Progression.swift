import Foundation

// MARK: - ProgressionStep

public struct ProgressionStep: Equatable, Codable, Hashable {
    public let degree: Int           // 1-7
    public let label: String         // e.g. "I", "V", "vi"
    public let qualityOverride: ChordQuality?  // nil = use diatonic default

    public init(degree: Int, label: String, qualityOverride: ChordQuality? = nil) {
        self.degree = degree
        self.label = label
        self.qualityOverride = qualityOverride
    }
}

// MARK: - ProgressionTemplate

public struct ProgressionTemplate: Equatable, Codable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let composer: String
    public let era: String
    public let steps: [ProgressionStep]
    public let isMajor: Bool
    public let description: String

    public init(
        id: String,
        name: String,
        composer: String,
        era: String,
        steps: [ProgressionStep],
        isMajor: Bool = true,
        description: String
    ) {
        self.id = id
        self.name = name
        self.composer = composer
        self.era = era
        self.steps = steps
        self.isMajor = isMajor
        self.description = description
    }

    /// Resolve this progression into concrete DiatonicChords for a given scale.
    public func resolve(in scale: Scale) -> [DiatonicChord] {
        let diatonic = DiatonicAnalysis.diatonicChords(for: scale)
        return steps.compactMap { step in
            guard step.degree >= 1, step.degree <= diatonic.count else { return nil }
            let dc = diatonic[step.degree - 1]
            if let override = step.qualityOverride {
                let overriddenType: ChordType
                switch override {
                case .major: overriddenType = .major
                case .minor: overriddenType = .minor
                case .diminished: overriddenType = .diminished
                case .augmented: overriddenType = .augmented
                default: overriddenType = dc.chordType
                }
                return DiatonicChord(
                    degree: dc.degree,
                    romanNumeral: step.label,
                    chordType: overriddenType,
                    root: dc.root,
                    harmonicFunction: dc.harmonicFunction,
                    functionLabel: dc.functionLabel,
                    description: dc.description
                )
            }
            return dc
        }
    }
}

// MARK: - Built-in Progressions

extension ProgressionTemplate {

    // MARK: Major

    public static let pachelbel = ProgressionTemplate(
        id: "pachelbel",
        name: "Pachelbel-Kanon",
        composer: "Johann Pachelbel",
        era: "~1680",
        steps: [
            ProgressionStep(degree: 1, label: "I"),
            ProgressionStep(degree: 5, label: "V"),
            ProgressionStep(degree: 6, label: "vi"),
            ProgressionStep(degree: 3, label: "iii"),
            ProgressionStep(degree: 4, label: "IV"),
            ProgressionStep(degree: 1, label: "I"),
            ProgressionStep(degree: 4, label: "IV"),
            ProgressionStep(degree: 5, label: "V"),
        ],
        description: "Der berühmte Kanon in D-Dur"
    )

    public static let fifties = ProgressionTemplate(
        id: "fifties",
        name: "50s Progression",
        composer: "Pop/Doo-Wop",
        era: "1950er",
        steps: [
            ProgressionStep(degree: 1, label: "I"),
            ProgressionStep(degree: 6, label: "vi"),
            ProgressionStep(degree: 4, label: "IV"),
            ProgressionStep(degree: 5, label: "V"),
        ],
        description: "Stand By Me, Earth Angel, etc."
    )

    public static let axisOfAwesome = ProgressionTemplate(
        id: "axis",
        name: "Axis of Awesome",
        composer: "Pop",
        era: "Modern",
        steps: [
            ProgressionStep(degree: 1, label: "I"),
            ProgressionStep(degree: 5, label: "V"),
            ProgressionStep(degree: 6, label: "vi"),
            ProgressionStep(degree: 4, label: "IV"),
        ],
        description: "Let It Be, No Woman No Cry, etc."
    )

    public static let andalusianMajor = ProgressionTemplate(
        id: "andalusian-major",
        name: "Andalusische Kadenz",
        composer: "Flamenco",
        era: "Traditionell",
        steps: [
            ProgressionStep(degree: 6, label: "vi"),
            ProgressionStep(degree: 5, label: "V"),
            ProgressionStep(degree: 4, label: "IV"),
            ProgressionStep(degree: 3, label: "iii"),
        ],
        description: "Typisch für spanische Musik"
    )

    public static let jazzTwoFiveOne = ProgressionTemplate(
        id: "jazz-251",
        name: "Jazz II-V-I",
        composer: "Jazz",
        era: "Klassiker",
        steps: [
            ProgressionStep(degree: 2, label: "ii"),
            ProgressionStep(degree: 5, label: "V"),
            ProgressionStep(degree: 1, label: "I"),
        ],
        description: "Die wichtigste Jazz-Kadenz"
    )

    public static let blues = ProgressionTemplate(
        id: "blues",
        name: "12-Takt Blues",
        composer: "Blues/Rock",
        era: "Klassiker",
        steps: [
            ProgressionStep(degree: 1, label: "I"),
            ProgressionStep(degree: 1, label: "I"),
            ProgressionStep(degree: 1, label: "I"),
            ProgressionStep(degree: 1, label: "I"),
            ProgressionStep(degree: 4, label: "IV"),
            ProgressionStep(degree: 4, label: "IV"),
            ProgressionStep(degree: 1, label: "I"),
            ProgressionStep(degree: 1, label: "I"),
            ProgressionStep(degree: 5, label: "V"),
            ProgressionStep(degree: 4, label: "IV"),
            ProgressionStep(degree: 1, label: "I"),
            ProgressionStep(degree: 5, label: "V"),
        ],
        description: "12-Takt-Blues-Schema"
    )

    // MARK: Minor

    public static let minorCadence = ProgressionTemplate(
        id: "minor-cadence",
        name: "Moll-Kadenz",
        composer: "Klassik",
        era: "Traditionell",
        steps: [
            ProgressionStep(degree: 1, label: "i"),
            ProgressionStep(degree: 4, label: "iv"),
            ProgressionStep(degree: 5, label: "v"),
            ProgressionStep(degree: 1, label: "i"),
        ],
        isMajor: false,
        description: "Klassische Moll-Kadenz"
    )

    public static let andalusianMinor = ProgressionTemplate(
        id: "andalusian-minor",
        name: "Andalusische Kadenz (Moll)",
        composer: "Flamenco",
        era: "Traditionell",
        steps: [
            ProgressionStep(degree: 1, label: "i"),
            ProgressionStep(degree: 7, label: "VII"),
            ProgressionStep(degree: 6, label: "VI"),
            ProgressionStep(degree: 5, label: "V", qualityOverride: .major),
        ],
        isMajor: false,
        description: "Hit The Road Jack, etc."
    )

    public static let minorPop = ProgressionTemplate(
        id: "minor-pop",
        name: "Moll Pop",
        composer: "Pop",
        era: "Modern",
        steps: [
            ProgressionStep(degree: 1, label: "i"),
            ProgressionStep(degree: 6, label: "VI"),
            ProgressionStep(degree: 7, label: "VII"),
            ProgressionStep(degree: 5, label: "v"),
        ],
        isMajor: false,
        description: "Beliebte Moll-Progression"
    )

    // MARK: All

    public static let allMajor: [ProgressionTemplate] = [
        .pachelbel, .fifties, .axisOfAwesome, .andalusianMajor, .jazzTwoFiveOne, .blues
    ]

    public static let allMinor: [ProgressionTemplate] = [
        .minorCadence, .andalusianMinor, .minorPop
    ]

    public static let all: [ProgressionTemplate] = allMajor + allMinor
}
