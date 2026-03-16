import XCTest
@testable import App
import FlowPianoCore
import Persistence

final class FlowPianoUITests: XCTestCase {
    @MainActor
    func testAppModelBootstrapsReadySnapshot() {
        let model = FlowPianoAppModel(settingsStore: InMemorySettingsStore(), useLiveSystemServices: false)

        XCTAssertTrue(model.snapshot.setupChecklist.allSatisfy(\.isComplete))
        XCTAssertEqual(model.snapshot.video.mode.rawValue, "dualCamera")
    }

    @MainActor
    func testAppModelActionsUpdateSnapshot() {
        let model = FlowPianoAppModel(settingsStore: InMemorySettingsStore(), useLiveSystemServices: false)
        let originalMainCameraID = model.snapshot.video.assignment.mainCameraID

        model.swapCameras()
        model.simulatePhrase()

        XCTAssertNotEqual(model.snapshot.video.assignment.mainCameraID, originalMainCameraID)
        XCTAssertFalse(model.snapshot.notation.recentSymbols.isEmpty)
    }

    @MainActor
    func testToggleInternalPianoUpdatesState() {
        let model = FlowPianoAppModel(settingsStore: InMemorySettingsStore(), useLiveSystemServices: false)
        let initialState = model.snapshot.audio.internalPianoEnabled

        model.toggleInternalPiano()

        XCTAssertNotEqual(model.snapshot.audio.internalPianoEnabled, initialState)
    }

    @MainActor
    func testCycleRoutingModeProgresses() {
        let model = FlowPianoAppModel(settingsStore: InMemorySettingsStore(), useLiveSystemServices: false)
        XCTAssertEqual(model.snapshot.audio.routingMode, .internalOnly)

        model.cycleRoutingMode()
        XCTAssertEqual(model.snapshot.audio.routingMode, .layered)

        model.cycleRoutingMode()
        XCTAssertEqual(model.snapshot.audio.routingMode, .externalOnly)

        model.cycleRoutingMode()
        XCTAssertEqual(model.snapshot.audio.routingMode, .internalOnly)
    }

    @MainActor
    func testToggleVirtualDevices() {
        let model = FlowPianoAppModel(settingsStore: InMemorySettingsStore(), useLiveSystemServices: false)
        let initialCameraInstalled = model.snapshot.virtualCamera.isInstalled

        model.toggleVirtualDevices()

        XCTAssertNotEqual(model.snapshot.virtualCamera.isInstalled, initialCameraInstalled)
    }

    @MainActor
    func testNudgeOverlayChangesPosition() {
        let model = FlowPianoAppModel(settingsStore: InMemorySettingsStore(), useLiveSystemServices: false)
        let originalX = model.snapshot.overlay.frame.x

        model.nudgeOverlay()

        XCTAssertNotEqual(model.snapshot.overlay.frame.x, originalX)
    }

    @MainActor
    func testOverlayVisibilityToggle() {
        let model = FlowPianoAppModel(settingsStore: InMemorySettingsStore(), useLiveSystemServices: false)
        XCTAssertTrue(model.snapshot.overlay.isVisible)

        model.setOverlayVisible(false)
        XCTAssertFalse(model.snapshot.overlay.isVisible)

        model.setOverlayVisible(true)
        XCTAssertTrue(model.snapshot.overlay.isVisible)
    }

    @MainActor
    func testSelectCamerasUpdatesAssignment() {
        let model = FlowPianoAppModel(settingsStore: InMemorySettingsStore(), useLiveSystemServices: false)

        model.selectMainCamera(id: "cam-keys")
        XCTAssertEqual(model.snapshot.video.assignment.mainCameraID, "cam-keys")

        model.selectPiPCamera(id: "cam-face")
        XCTAssertEqual(model.snapshot.video.assignment.pipCameraID, "cam-face")
    }

    @MainActor
    func testStudioMonitorToggles() {
        let model = FlowPianoAppModel(settingsStore: InMemorySettingsStore(), useLiveSystemServices: false)

        model.setStudioNotationEnabled(false)
        XCTAssertFalse(model.snapshot.settings.studioMonitor.notationEnabled)

        model.setStudioMetersEnabled(false)
        XCTAssertFalse(model.snapshot.settings.studioMonitor.metersEnabled)

        model.setStudioDiagnosticsEnabled(false)
        XCTAssertFalse(model.snapshot.settings.studioMonitor.diagnosticsEnabled)

        model.setStudioEventLogEnabled(false)
        XCTAssertFalse(model.snapshot.settings.studioMonitor.eventLogEnabled)

        model.setStudioLatencyEnabled(false)
        XCTAssertFalse(model.snapshot.settings.studioMonitor.latencyIndicatorEnabled)
    }

    @MainActor
    func testSaveSettingsDoesNotCrash() {
        let model = FlowPianoAppModel(settingsStore: InMemorySettingsStore(), useLiveSystemServices: false)
        model.saveSettings()
        // No crash = success for InMemorySettingsStore
    }
}
