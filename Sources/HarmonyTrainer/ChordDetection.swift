import Foundation

public enum ChordDetection {
    /// Detect the best-matching chord from a set of MIDI note numbers.
    /// Returns nil if fewer than 3 distinct pitch classes or no match found.
    public static func detect(from midiNotes: [Int]) -> Chord? {
        let pitchClassValues = Set(midiNotes.map { (($0 % 12) + 12) % 12 })
        guard pitchClassValues.count >= 3 else { return nil }

        let sortedPC = pitchClassValues.sorted()
        let bassNote = midiNotes.min() ?? 0
        let bassPitchClass = ((bassNote % 12) + 12) % 12

        for chordType in ChordType.allTypes {
            for potentialRoot in sortedPC {
                let expectedIntervals = Set(chordType.intervals)
                let actualIntervals = Set(sortedPC.map { ($0 - potentialRoot + 12) % 12 })

                guard actualIntervals == expectedIntervals else { continue }

                let root = PitchClass(rawValue: potentialRoot)!
                let inversion = determineInversion(
                    root: potentialRoot,
                    bassPC: bassPitchClass,
                    intervals: chordType.intervals
                )
                return Chord(root: root, chordType: chordType, inversion: inversion)
            }
        }

        return nil
    }

    /// Returns all possible chord interpretations ranked by likelihood.
    public static func detectAll(from midiNotes: [Int]) -> [Chord] {
        let pitchClassValues = Set(midiNotes.map { (($0 % 12) + 12) % 12 })
        guard pitchClassValues.count >= 3 else { return [] }

        let sortedPC = pitchClassValues.sorted()
        let bassNote = midiNotes.min() ?? 0
        let bassPitchClass = ((bassNote % 12) + 12) % 12
        var results: [Chord] = []

        for chordType in ChordType.allTypes {
            for potentialRoot in sortedPC {
                let expectedIntervals = Set(chordType.intervals)
                let actualIntervals = Set(sortedPC.map { ($0 - potentialRoot + 12) % 12 })

                guard actualIntervals == expectedIntervals else { continue }

                let root = PitchClass(rawValue: potentialRoot)!
                let inversion = determineInversion(
                    root: potentialRoot,
                    bassPC: bassPitchClass,
                    intervals: chordType.intervals
                )
                results.append(Chord(root: root, chordType: chordType, inversion: inversion))
            }
        }

        return results
    }

    private static func determineInversion(root: Int, bassPC: Int, intervals: [Int]) -> Inversion {
        guard bassPC != root else { return .root }
        let chordPCs = intervals.map { (root + $0) % 12 }
        guard let bassIndex = chordPCs.firstIndex(of: bassPC) else { return .root }
        switch bassIndex {
        case 1: return .first
        case 2: return .second
        case 3: return .third
        default: return .root
        }
    }
}
