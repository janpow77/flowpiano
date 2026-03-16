import Foundation
import AudioEngine
import Diagnostics
import HarmonyTrainer
import LayoutEngine
import MIDIEngine
import NotationEngine

public struct StudioMonitorState: Equatable, Codable {
    public var notationEnabled: Bool
    public var diagnosticsEnabled: Bool
    public var metersEnabled: Bool
    public var eventLogEnabled: Bool
    public var latencyIndicatorEnabled: Bool
    public var harmonyTrainerEnabled: Bool

    public init(
        notationEnabled: Bool = true,
        diagnosticsEnabled: Bool = true,
        metersEnabled: Bool = true,
        eventLogEnabled: Bool = true,
        latencyIndicatorEnabled: Bool = true,
        harmonyTrainerEnabled: Bool = false
    ) {
        self.notationEnabled = notationEnabled
        self.diagnosticsEnabled = diagnosticsEnabled
        self.metersEnabled = metersEnabled
        self.eventLogEnabled = eventLogEnabled
        self.latencyIndicatorEnabled = latencyIndicatorEnabled
        self.harmonyTrainerEnabled = harmonyTrainerEnabled
    }
}

public struct StudioMonitorSnapshot: Equatable, Codable {
    public var visibleLayers: [LayerKind]
    public var notation: NotationState?
    public var audioMeters: AudioMeterState?
    public var midiLog: [MIDIEventLogEntry]
    public var diagnostics: DiagnosticsReport?
    public var latencyMilliseconds: Double?
    public var harmonyTrainer: HarmonyTrainerState?

    public init(
        visibleLayers: [LayerKind],
        notation: NotationState?,
        audioMeters: AudioMeterState?,
        midiLog: [MIDIEventLogEntry],
        diagnostics: DiagnosticsReport?,
        latencyMilliseconds: Double?,
        harmonyTrainer: HarmonyTrainerState? = nil
    ) {
        self.visibleLayers = visibleLayers
        self.notation = notation
        self.audioMeters = audioMeters
        self.midiLog = midiLog
        self.diagnostics = diagnostics
        self.latencyMilliseconds = latencyMilliseconds
        self.harmonyTrainer = harmonyTrainer
    }
}

public enum StudioMonitor {
    public static func buildSnapshot(
        layout: LayoutConfiguration,
        state: StudioMonitorState,
        notation: NotationState,
        audio: AudioEngineState,
        midi: MIDIConnectionStatus,
        diagnostics: DiagnosticsReport,
        latencyMilliseconds: Double?,
        harmonyTrainer: HarmonyTrainerState? = nil
    ) -> StudioMonitorSnapshot {
        let visibleLayers = LayoutEngine.visibleLayers(in: layout, for: .studioMonitor)
            .map(\.kind)
            .filter { kind in
                switch kind {
                case .musicStaff:
                    return state.notationEnabled
                case .audioMeters:
                    return state.metersEnabled
                case .midiEventLog:
                    return state.eventLogEnabled
                case .latencyIndicator:
                    return state.latencyIndicatorEnabled
                case .diagnostics:
                    return state.diagnosticsEnabled
                case .harmonyTrainer:
                    return state.harmonyTrainerEnabled
                case .mainCamera, .pipCamera, .midiOverlay:
                    return true
                }
            }

        let resolvedHarmonyTrainer: HarmonyTrainerState?
        if state.harmonyTrainerEnabled, let ht = harmonyTrainer, ht.isEnabled {
            resolvedHarmonyTrainer = ht
        } else {
            resolvedHarmonyTrainer = nil
        }

        return StudioMonitorSnapshot(
            visibleLayers: visibleLayers,
            notation: state.notationEnabled ? notation : nil,
            audioMeters: state.metersEnabled ? audio.meters : nil,
            midiLog: state.eventLogEnabled ? midi.eventLog : [],
            diagnostics: state.diagnosticsEnabled ? diagnostics : nil,
            latencyMilliseconds: state.latencyIndicatorEnabled ? latencyMilliseconds : nil,
            harmonyTrainer: resolvedHarmonyTrainer
        )
    }
}
