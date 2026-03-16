import XCTest
@testable import FlowPianoCore
import Foundation

final class StartupSmokeTests: XCTestCase {
    func testPreviewProfileProducesReleaseReadySession() throws {
        let coordinator = FlowPianoSessionCoordinator()
        coordinator.installPreviewHardwareProfile()
        try coordinator.startSession()

        XCTAssertTrue(coordinator.snapshot.setupChecklist.allSatisfy(\.isComplete))
        XCTAssertTrue(coordinator.snapshot.diagnostics.isReleaseReady)
        XCTAssertNotEqual(coordinator.snapshot.audio.runtime.pianoSoundBankSource, .unavailable)
    }

    func testPublicSceneRemainsSanitizedAfterOverlayChanges() throws {
        let coordinator = FlowPianoSessionCoordinator()
        coordinator.installPreviewHardwareProfile()
        try coordinator.startSession()

        coordinator.moveOverlay(toX: 200, y: 840)
        coordinator.resizeOverlay(width: 1200, height: 110)

        XCTAssertTrue(coordinator.snapshot.publicScene.layers.allSatisfy(\.kind.isPublicSafe))
        XCTAssertTrue(coordinator.snapshot.studioMonitor.visibleLayers.contains(.midiEventLog))
    }

    func testPreviewProfileWritesPublicationArtifacts() throws {
        let coordinator = FlowPianoSessionCoordinator()
        coordinator.installPreviewHardwareProfile()
        try coordinator.startSession()

        let fileManager = FileManager.default
        let cameraPath = coordinator.snapshot.virtualCamera.publicationPath
        let audioPath = coordinator.snapshot.virtualAudio.publicationPath

        XCTAssertNotNil(cameraPath)
        XCTAssertNotNil(audioPath)
        XCTAssertTrue(cameraPath.map { fileManager.fileExists(atPath: $0) } ?? false)
        XCTAssertTrue(audioPath.map { fileManager.fileExists(atPath: $0) } ?? false)
    }
}
