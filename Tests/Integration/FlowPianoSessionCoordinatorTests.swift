import XCTest
@testable import FlowPianoCore
import LayoutEngine
import MIDIEngine
import Persistence
import Settings

final class FlowPianoSessionCoordinatorTests: XCTestCase {
    func testCoordinatorPublishesOnlyPublicSafeLayers() throws {
        let coordinator = FlowPianoSessionCoordinator()
        coordinator.installPreviewHardwareProfile()
        try coordinator.startSession()

        XCTAssertTrue(coordinator.snapshot.publicScene.layers.allSatisfy(\.kind.isPublicSafe))
        XCTAssertTrue(coordinator.snapshot.virtualCamera.isPublishing)
        XCTAssertTrue(coordinator.snapshot.virtualAudio.isPublishing)
    }

    func testCoordinatorProcessesMIDIIntoNotationAndOverlay() throws {
        let coordinator = FlowPianoSessionCoordinator()
        coordinator.installPreviewHardwareProfile()
        try coordinator.startSession()

        try coordinator.receiveMIDIEvent(MIDIEvent(note: 72, velocity: 100, isNoteOn: true, sourceDeviceID: "midi-main"))
        try coordinator.receiveMIDIEvent(MIDIEvent(note: 72, velocity: 0, isNoteOn: false, sourceDeviceID: "midi-main"))

        XCTAssertFalse(coordinator.snapshot.notation.recentSymbols.isEmpty)
        XCTAssertTrue(coordinator.snapshot.overlay.activeKeys.isEmpty)
        XCTAssertEqual(coordinator.snapshot.midi.eventLog.count, 2)
    }

    func testCoordinatorReportsUnsafeLayoutWhileKeepingPublicOutputSanitized() throws {
        let store = InMemorySettingsStore()
        let unsafeLayout = LayoutConfiguration(
            layers: AppSettings().layout.layers.map { layer in
                guard layer.kind == .diagnostics else { return layer }
                var updated = layer
                updated.visibility.publicVisible = true
                return updated
            }
        )

        try store.save(AppSettings(layout: unsafeLayout), forKey: "flowpiano-settings")

        let coordinator = FlowPianoSessionCoordinator(settingsStore: store)
        coordinator.installPreviewHardwareProfile()
        try coordinator.startSession()

        XCTAssertEqual(coordinator.snapshot.publicSceneViolations, [.diagnostics])
        XCTAssertTrue(coordinator.snapshot.publicScene.layers.allSatisfy(\.kind.isPublicSafe))
        XCTAssertTrue(coordinator.snapshot.diagnostics.issues.contains(where: { $0.code == .publicSceneViolation }))
    }

    func testOverlayVisibilityRemovesOverlayFromBothTargetsAndChecklist() throws {
        let coordinator = FlowPianoSessionCoordinator()
        coordinator.installPreviewHardwareProfile()
        try coordinator.startSession()

        coordinator.setOverlayVisible(false)

        XCTAssertFalse(coordinator.snapshot.overlay.isVisible)
        XCTAssertFalse(coordinator.snapshot.publicScene.layers.contains(where: { $0.kind == .midiOverlay }))
        XCTAssertFalse(coordinator.snapshot.studioMonitor.visibleLayers.contains(.midiOverlay))
        XCTAssertEqual(
            coordinator.snapshot.setupChecklist.first(where: { $0.step == .overlayPlacement })?.isComplete,
            false
        )
    }

    func testStudioMonitorStateControlsLocalOnlyLayers() throws {
        let coordinator = FlowPianoSessionCoordinator()
        coordinator.installPreviewHardwareProfile()
        try coordinator.startSession()

        coordinator.setStudioMonitorState(
            StudioMonitorState(
                notationEnabled: false,
                diagnosticsEnabled: false,
                metersEnabled: false,
                eventLogEnabled: false,
                latencyIndicatorEnabled: false
            )
        )

        XCTAssertFalse(coordinator.snapshot.studioMonitor.visibleLayers.contains(.musicStaff))
        XCTAssertFalse(coordinator.snapshot.studioMonitor.visibleLayers.contains(.audioMeters))
        XCTAssertFalse(coordinator.snapshot.studioMonitor.visibleLayers.contains(.midiEventLog))
        XCTAssertFalse(coordinator.snapshot.studioMonitor.visibleLayers.contains(.latencyIndicator))
        XCTAssertFalse(coordinator.snapshot.studioMonitor.visibleLayers.contains(.diagnostics))
        XCTAssertNil(coordinator.snapshot.studioMonitor.notation)
        XCTAssertNil(coordinator.snapshot.studioMonitor.audioMeters)
        XCTAssertNil(coordinator.snapshot.studioMonitor.diagnostics)
        XCTAssertNil(coordinator.snapshot.studioMonitor.latencyMilliseconds)
        XCTAssertTrue(coordinator.snapshot.studioMonitor.midiLog.isEmpty)
    }

    func testSettingsMutationsPersistAutomatically() throws {
        let store = InMemorySettingsStore()
        let coordinator = FlowPianoSessionCoordinator(settingsStore: store)

        coordinator.installPreviewHardwareProfile()
        coordinator.moveOverlay(toX: 180, y: 860)
        coordinator.resizeOverlay(width: 1400, height: 100)
        coordinator.setOverlayLabelsVisible(false)

        let persisted = try store.load(AppSettings.self, forKey: "flowpiano-settings")
        let overlayLayer = persisted?.layout.layers.first(where: { $0.kind == .midiOverlay })

        XCTAssertEqual(overlayLayer?.frame.x, 180)
        XCTAssertEqual(overlayLayer?.frame.y, 860)
        XCTAssertEqual(overlayLayer?.frame.width, 1400)
        XCTAssertEqual(overlayLayer?.frame.height, 100)
        XCTAssertEqual(persisted?.overlay.showLabels, false)
    }
}
