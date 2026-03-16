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
}
