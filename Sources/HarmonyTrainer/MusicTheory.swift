import Foundation

// MARK: - PitchClass

public enum PitchClass: Int, Codable, CaseIterable, Equatable, Hashable {
    case c = 0, cSharp, d, dSharp, e, f, fSharp, g, gSharp, a, aSharp, b

    public init(midiNote: Int) {
        self.init(rawValue: ((midiNote % 12) + 12) % 12)!
    }

    public var name: String {
        switch self {
        case .c: return "C"
        case .cSharp: return "C#"
        case .d: return "D"
        case .dSharp: return "D#"
        case .e: return "E"
        case .f: return "F"
        case .fSharp: return "F#"
        case .g: return "G"
        case .gSharp: return "G#"
        case .a: return "A"
        case .aSharp: return "A#"
        case .b: return "B"
        }
    }

    public var germanName: String {
        switch self {
        case .c: return "C"
        case .cSharp: return "Cis"
        case .d: return "D"
        case .dSharp: return "Dis"
        case .e: return "E"
        case .f: return "F"
        case .fSharp: return "Fis"
        case .g: return "G"
        case .gSharp: return "Gis"
        case .a: return "A"
        case .aSharp: return "B"
        case .b: return "H"
        }
    }

    public var flatName: String {
        switch self {
        case .c: return "C"
        case .cSharp: return "Db"
        case .d: return "D"
        case .dSharp: return "Eb"
        case .e: return "E"
        case .f: return "F"
        case .fSharp: return "Gb"
        case .g: return "G"
        case .gSharp: return "Ab"
        case .a: return "A"
        case .aSharp: return "Bb"
        case .b: return "B"
        }
    }

    public func transposed(by semitones: Int) -> PitchClass {
        PitchClass(rawValue: ((rawValue + semitones) % 12 + 12) % 12)!
    }
}

// MARK: - ScaleType

public struct ScaleType: Equatable, Codable, Hashable {
    public let name: String
    public let intervals: [Int]

    public init(name: String, intervals: [Int]) {
        self.name = name
        self.intervals = intervals
    }

    public static let major = ScaleType(name: "Major", intervals: [0, 2, 4, 5, 7, 9, 11])
    public static let naturalMinor = ScaleType(name: "Natural Minor", intervals: [0, 2, 3, 5, 7, 8, 10])
    public static let harmonicMinor = ScaleType(name: "Harmonic Minor", intervals: [0, 2, 3, 5, 7, 8, 11])
}

// MARK: - Scale

public struct Scale: Equatable, Codable, Hashable {
    public let root: PitchClass
    public let scaleType: ScaleType

    public init(root: PitchClass, scaleType: ScaleType) {
        self.root = root
        self.scaleType = scaleType
    }

    public var pitchClasses: [PitchClass] {
        scaleType.intervals.map { root.transposed(by: $0) }
    }

    public func contains(_ pc: PitchClass) -> Bool {
        pitchClasses.contains(pc)
    }

    /// Returns the 1-based scale degree (1-7) of a pitch class, or nil if not in scale.
    public func degree(of pc: PitchClass) -> Int? {
        guard let index = pitchClasses.firstIndex(of: pc) else { return nil }
        return index + 1
    }
}

// MARK: - ChordQuality

public enum ChordQuality: String, Codable, CaseIterable, Equatable, Hashable {
    case major
    case minor
    case diminished
    case augmented
    case dominant7
    case major7
    case minor7
    case diminished7

    public var symbol: String {
        switch self {
        case .major: return ""
        case .minor: return "m"
        case .diminished: return "\u{00B0}"  // °
        case .augmented: return "+"
        case .dominant7: return "7"
        case .major7: return "maj7"
        case .minor7: return "m7"
        case .diminished7: return "\u{00B0}7"
        }
    }

    public var germanName: String {
        switch self {
        case .major: return "Dur"
        case .minor: return "Moll"
        case .diminished: return "Vermindert"
        case .augmented: return "Übermäßig"
        case .dominant7: return "Dominant-7"
        case .major7: return "Major-7"
        case .minor7: return "Moll-7"
        case .diminished7: return "Verm.-7"
        }
    }
}

// MARK: - ChordType

public struct ChordType: Equatable, Codable, Hashable {
    public let quality: ChordQuality
    public let intervals: [Int]

    public init(quality: ChordQuality, intervals: [Int]) {
        self.quality = quality
        self.intervals = intervals
    }

    public static let major       = ChordType(quality: .major, intervals: [0, 4, 7])
    public static let minor       = ChordType(quality: .minor, intervals: [0, 3, 7])
    public static let diminished  = ChordType(quality: .diminished, intervals: [0, 3, 6])
    public static let augmented   = ChordType(quality: .augmented, intervals: [0, 4, 8])
    public static let dominant7   = ChordType(quality: .dominant7, intervals: [0, 4, 7, 10])
    public static let major7      = ChordType(quality: .major7, intervals: [0, 4, 7, 11])
    public static let minor7      = ChordType(quality: .minor7, intervals: [0, 3, 7, 10])
    public static let diminished7 = ChordType(quality: .diminished7, intervals: [0, 3, 6, 9])

    /// All known chord types, triads first (preferred in detection).
    public static let allTypes: [ChordType] = [
        .major, .minor, .diminished, .augmented,
        .dominant7, .major7, .minor7, .diminished7
    ]
}

// MARK: - Inversion

public enum Inversion: Int, Codable, CaseIterable, Equatable, Hashable {
    case root = 0
    case first
    case second
    case third
}

// MARK: - Chord

public struct Chord: Equatable, Codable, Hashable {
    public let root: PitchClass
    public let chordType: ChordType
    public let inversion: Inversion

    public init(root: PitchClass, chordType: ChordType, inversion: Inversion = .root) {
        self.root = root
        self.chordType = chordType
        self.inversion = inversion
    }

    public var pitchClasses: [PitchClass] {
        chordType.intervals.map { root.transposed(by: $0) }
    }

    public var displayName: String {
        root.name + chordType.quality.symbol
    }

    public var germanDisplayName: String {
        root.germanName + chordType.quality.symbol
    }

    /// Returns MIDI notes for this chord starting at the given octave.
    public func midiNotes(octave: Int = 3) -> [Int] {
        let baseMidi = (octave + 1) * 12 + root.rawValue
        var notes = chordType.intervals.map { baseMidi + $0 }

        switch inversion {
        case .root:
            break
        case .first where notes.count >= 3:
            notes[0] += 12
            notes.sort()
        case .second where notes.count >= 3:
            notes[0] += 12
            notes[1] += 12
            notes.sort()
        case .third where notes.count >= 4:
            notes[0] += 12
            notes[1] += 12
            notes[2] += 12
            notes.sort()
        default:
            break
        }

        return notes
    }
}
