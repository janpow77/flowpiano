import Foundation
import LayoutEngine
import MIDIEngine

public struct OverlayKeyState: Equatable, Codable, Identifiable {
    public var note: Int
    public var velocity: Int
    public var isActive: Bool

    public var id: Int { note }

    public init(note: Int, velocity: Int, isActive: Bool) {
        self.note = note
        self.velocity = velocity
        self.isActive = isActive
    }
}

public struct MIDIOverlayState: Equatable, Codable {
    public var isVisible: Bool
    public var showLabels: Bool
    public var frame: LayerFrame
    public var activeKeys: [OverlayKeyState]

    public init(
        isVisible: Bool = true,
        showLabels: Bool = true,
        frame: LayerFrame = LayerFrame(x: 60, y: 900, width: 1800, height: 120),
        activeKeys: [OverlayKeyState] = []
    ) {
        self.isVisible = isVisible
        self.showLabels = showLabels
        self.frame = frame
        self.activeKeys = activeKeys
    }
}

public final class OverlayEngine {
    public private(set) var state: MIDIOverlayState

    public init(initialState: MIDIOverlayState = MIDIOverlayState()) {
        state = initialState
    }

    public func setVisible(_ isVisible: Bool) {
        state.isVisible = isVisible
    }

    public func setShowLabels(_ showLabels: Bool) {
        state.showLabels = showLabels
    }

    public func setFrame(_ frame: LayerFrame) {
        state.frame = frame
    }

    public func update(from midiStatus: MIDIConnectionStatus) {
        update(activeVelocities: midiStatus.activeVelocities)
    }

    public func update(activeVelocities: [Int: Int]) {
        state.activeKeys = activeVelocities.keys.sorted().map { note in
            OverlayKeyState(note: note, velocity: activeVelocities[note] ?? 0, isActive: true)
        }
    }
}
