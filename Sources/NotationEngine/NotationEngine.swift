import Foundation
import MIDIEngine

public enum NotationDisplayMode: String, Codable {
    case scrolling
    case staticMapping
}

public struct StaffSymbol: Equatable, Codable, Identifiable {
    public let id: Int
    public let note: Int
    public let noteName: String
    public let octave: Int
    public let velocity: Int
    public let isActive: Bool

    public init(id: Int, note: Int, noteName: String, octave: Int, velocity: Int, isActive: Bool) {
        self.id = id
        self.note = note
        self.noteName = noteName
        self.octave = octave
        self.velocity = velocity
        self.isActive = isActive
    }
}

public struct NotationState: Equatable, Codable {
    public var displayMode: NotationDisplayMode
    public var activeSymbols: [StaffSymbol]
    public var recentSymbols: [StaffSymbol]

    public init(displayMode: NotationDisplayMode = .scrolling, activeSymbols: [StaffSymbol] = [], recentSymbols: [StaffSymbol] = []) {
        self.displayMode = displayMode
        self.activeSymbols = activeSymbols
        self.recentSymbols = recentSymbols
    }
}

public final class NotationEngine {
    public private(set) var state: NotationState
    private var activeByNote: [Int: StaffSymbol] = [:]
    private var nextSymbolID = 1

    public init(displayMode: NotationDisplayMode = .scrolling) {
        state = NotationState(displayMode: displayMode)
    }

    public func setDisplayMode(_ displayMode: NotationDisplayMode) {
        state.displayMode = displayMode
    }

    public func consume(_ event: MIDIEvent) {
        if event.isNoteOn && event.velocity > 0 {
            let symbol = StaffSymbol(
                id: nextSymbolID,
                note: event.note,
                noteName: noteName(for: event.note),
                octave: octave(for: event.note),
                velocity: event.velocity,
                isActive: true
            )
            nextSymbolID += 1
            activeByNote[event.note] = symbol
        } else if let symbol = activeByNote.removeValue(forKey: event.note) {
            let completed = StaffSymbol(
                id: symbol.id,
                note: symbol.note,
                noteName: symbol.noteName,
                octave: symbol.octave,
                velocity: symbol.velocity,
                isActive: false
            )
            state.recentSymbols.insert(completed, at: 0)
            if state.recentSymbols.count > 16 {
                state.recentSymbols.removeLast(state.recentSymbols.count - 16)
            }
        }

        state.activeSymbols = activeByNote.values.sorted { $0.note < $1.note }
    }

    public func reset() {
        activeByNote = [:]
        state.activeSymbols = []
        state.recentSymbols = []
    }

    private func noteName(for note: Int) -> String {
        let pitchClasses = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return pitchClasses[((note % 12) + 12) % 12]
    }

    private func octave(for note: Int) -> Int {
        (note / 12) - 1
    }
}
