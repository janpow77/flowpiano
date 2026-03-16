import Foundation

// MARK: - HarmonicFunction

public enum HarmonicFunction: String, Codable, Equatable, Hashable {
    case tonic
    case subdominant
    case dominant

    public var germanName: String {
        switch self {
        case .tonic: return "Tonika"
        case .subdominant: return "Subdominante"
        case .dominant: return "Dominante"
        }
    }

    public var abbreviation: String {
        switch self {
        case .tonic: return "T"
        case .subdominant: return "S"
        case .dominant: return "D"
        }
    }
}

// MARK: - DiatonicChord

public struct DiatonicChord: Equatable, Codable, Hashable {
    public let degree: Int                      // 1-7
    public let romanNumeral: String             // "I", "ii", "iii", "IV", "V", "vi", "vii°"
    public let chordType: ChordType
    public let root: PitchClass
    public let harmonicFunction: HarmonicFunction
    public let functionLabel: String            // "T", "Sp", "Dp", "S", "D", "Tp", "D⁷"
    public let description: String              // e.g. "Ruhepunkt", "Spannungsaufbau"

    public init(
        degree: Int,
        romanNumeral: String,
        chordType: ChordType,
        root: PitchClass,
        harmonicFunction: HarmonicFunction,
        functionLabel: String,
        description: String
    ) {
        self.degree = degree
        self.romanNumeral = romanNumeral
        self.chordType = chordType
        self.root = root
        self.harmonicFunction = harmonicFunction
        self.functionLabel = functionLabel
        self.description = description
    }
}

// MARK: - DiatonicAnalysis

public enum DiatonicAnalysis {
    /// Build the 7 diatonic triads for a given scale.
    public static func diatonicChords(for scale: Scale) -> [DiatonicChord] {
        let pcs = scale.pitchClasses
        let isMajor = scale.scaleType == .major

        let templates: [(roman: String, quality: ChordQuality, function: HarmonicFunction, label: String, desc: String)]

        if isMajor {
            templates = [
                ("I",    .major,      .tonic,       "T",   "Ruhepunkt"),
                ("ii",   .minor,      .subdominant, "Sp",  "Subdominant-Parallele"),
                ("iii",  .minor,      .dominant,    "Dp",  "Dominant-Parallele"),
                ("IV",   .major,      .subdominant, "S",   "Spannungsaufbau"),
                ("V",    .major,      .dominant,    "D",   "Höchste Spannung"),
                ("vi",   .minor,      .tonic,       "Tp",  "Tonika-Parallele"),
                ("vii\u{00B0}", .diminished, .dominant, "D\u{2077}", "Leittonakkord"),
            ]
        } else {
            templates = [
                ("i",    .minor,      .tonic,       "t",   "Ruhepunkt"),
                ("ii\u{00B0}", .diminished, .subdominant, "s\u{00B0}", "Subdominant-Vertreter"),
                ("III",  .major,      .tonic,       "tP",  "Tonikaparallele"),
                ("iv",   .minor,      .subdominant, "s",   "Spannungsaufbau"),
                ("v",    .minor,      .dominant,    "d",   "Moll-Dominante"),
                ("VI",   .major,      .subdominant, "sP",  "Subdominantparallele"),
                ("VII",  .major,      .dominant,    "VII", "Subtonikaakkord"),
            ]
        }

        return templates.enumerated().map { index, tmpl in
            let chordType: ChordType
            switch tmpl.quality {
            case .major: chordType = .major
            case .minor: chordType = .minor
            case .diminished: chordType = .diminished
            case .augmented: chordType = .augmented
            default: chordType = .major
            }

            return DiatonicChord(
                degree: index + 1,
                romanNumeral: tmpl.roman,
                chordType: chordType,
                root: pcs[index],
                harmonicFunction: tmpl.function,
                functionLabel: tmpl.label,
                description: tmpl.desc
            )
        }
    }

    /// Analyze a detected chord against a key.
    /// Returns the matching DiatonicChord if the chord root is a scale degree
    /// and the chord quality matches the expected diatonic quality.
    public static func analyze(chord: Chord, in scale: Scale) -> DiatonicChord? {
        let diatonic = diatonicChords(for: scale)
        return diatonic.first { dc in
            dc.root == chord.root && dc.chordType.quality == chord.chordType.quality
        }
    }

    /// Looser analysis: returns diatonic chord matching just the root, regardless of quality.
    /// Useful for identifying borrowed chords or modal interchange.
    public static func analyzeByRoot(chord: Chord, in scale: Scale) -> DiatonicChord? {
        let diatonic = diatonicChords(for: scale)
        return diatonic.first { $0.root == chord.root }
    }
}
