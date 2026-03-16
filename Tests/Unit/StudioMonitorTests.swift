import XCTest
@testable import StudioMonitor
import AudioEngine
import Diagnostics
import LayoutEngine
import MIDIEngine
import NotationEngine

final class StudioMonitorTests: XCTestCase {
    private func makeDefaultInputs() -> (LayoutConfiguration, StudioMonitorState, NotationState, AudioEngineState, MIDIConnectionStatus, DiagnosticsReport) {
        (
            .default,
            StudioMonitorState(),
            NotationState(),
            AudioEngineState(),
            MIDIConnectionStatus(),
            DiagnosticsReport()
        )
    }

    func testAllLayersVisibleByDefault() {
        let (layout, state, notation, audio, midi, diagnostics) = makeDefaultInputs()

        let snapshot = StudioMonitor.buildSnapshot(
            layout: layout, state: state, notation: notation,
            audio: audio, midi: midi, diagnostics: diagnostics,
            latencyMilliseconds: 20
        )

        XCTAssertTrue(snapshot.visibleLayers.contains(.musicStaff))
        XCTAssertTrue(snapshot.visibleLayers.contains(.audioMeters))
        XCTAssertTrue(snapshot.visibleLayers.contains(.midiEventLog))
        XCTAssertTrue(snapshot.visibleLayers.contains(.diagnostics))
        XCTAssertTrue(snapshot.visibleLayers.contains(.latencyIndicator))
        XCTAssertNotNil(snapshot.notation)
        XCTAssertNotNil(snapshot.audioMeters)
        XCTAssertNotNil(snapshot.diagnostics)
        XCTAssertNotNil(snapshot.latencyMilliseconds)
    }

    func testDisablingNotationHidesItFromSnapshot() {
        let (layout, _, notation, audio, midi, diagnostics) = makeDefaultInputs()
        var state = StudioMonitorState()
        state.notationEnabled = false

        let snapshot = StudioMonitor.buildSnapshot(
            layout: layout, state: state, notation: notation,
            audio: audio, midi: midi, diagnostics: diagnostics,
            latencyMilliseconds: 20
        )

        XCTAssertFalse(snapshot.visibleLayers.contains(.musicStaff))
        XCTAssertNil(snapshot.notation)
    }

    func testDisablingMetersHidesMeters() {
        let (layout, _, notation, audio, midi, diagnostics) = makeDefaultInputs()
        var state = StudioMonitorState()
        state.metersEnabled = false

        let snapshot = StudioMonitor.buildSnapshot(
            layout: layout, state: state, notation: notation,
            audio: audio, midi: midi, diagnostics: diagnostics,
            latencyMilliseconds: 20
        )

        XCTAssertFalse(snapshot.visibleLayers.contains(.audioMeters))
        XCTAssertNil(snapshot.audioMeters)
    }

    func testDisablingEventLogHidesLog() {
        let (layout, _, notation, audio, midi, diagnostics) = makeDefaultInputs()
        var state = StudioMonitorState()
        state.eventLogEnabled = false

        let snapshot = StudioMonitor.buildSnapshot(
            layout: layout, state: state, notation: notation,
            audio: audio, midi: midi, diagnostics: diagnostics,
            latencyMilliseconds: 20
        )

        XCTAssertFalse(snapshot.visibleLayers.contains(.midiEventLog))
        XCTAssertTrue(snapshot.midiLog.isEmpty)
    }

    func testDisablingDiagnosticsHidesDiagnostics() {
        let (layout, _, notation, audio, midi, diagnostics) = makeDefaultInputs()
        var state = StudioMonitorState()
        state.diagnosticsEnabled = false

        let snapshot = StudioMonitor.buildSnapshot(
            layout: layout, state: state, notation: notation,
            audio: audio, midi: midi, diagnostics: diagnostics,
            latencyMilliseconds: 20
        )

        XCTAssertFalse(snapshot.visibleLayers.contains(.diagnostics))
        XCTAssertNil(snapshot.diagnostics)
    }

    func testDisablingLatencyHidesLatency() {
        let (layout, _, notation, audio, midi, diagnostics) = makeDefaultInputs()
        var state = StudioMonitorState()
        state.latencyIndicatorEnabled = false

        let snapshot = StudioMonitor.buildSnapshot(
            layout: layout, state: state, notation: notation,
            audio: audio, midi: midi, diagnostics: diagnostics,
            latencyMilliseconds: 20
        )

        XCTAssertFalse(snapshot.visibleLayers.contains(.latencyIndicator))
        XCTAssertNil(snapshot.latencyMilliseconds)
    }

    func testPublicSafeLayersAlwaysVisible() {
        let (layout, _, notation, audio, midi, diagnostics) = makeDefaultInputs()
        var state = StudioMonitorState()
        state.notationEnabled = false
        state.metersEnabled = false
        state.eventLogEnabled = false
        state.diagnosticsEnabled = false
        state.latencyIndicatorEnabled = false

        let snapshot = StudioMonitor.buildSnapshot(
            layout: layout, state: state, notation: notation,
            audio: audio, midi: midi, diagnostics: diagnostics,
            latencyMilliseconds: 20
        )

        XCTAssertTrue(snapshot.visibleLayers.contains(.mainCamera))
        XCTAssertTrue(snapshot.visibleLayers.contains(.pipCamera))
        XCTAssertTrue(snapshot.visibleLayers.contains(.midiOverlay))
    }
}
