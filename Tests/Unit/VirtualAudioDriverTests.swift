import XCTest
@testable import VirtualAudioDriver
import AudioEngine

final class VirtualAudioDriverTests: XCTestCase {
    func testInstallAndUninstall() {
        let driver = VirtualAudioDriver()
        XCTAssertFalse(driver.status.isInstalled)

        driver.install()
        XCTAssertTrue(driver.status.isInstalled)
        XCTAssertNotNil(driver.status.publicationPath)

        driver.uninstall()
        XCTAssertFalse(driver.status.isInstalled)
        XCTAssertFalse(driver.status.isPublishing)
    }

    func testPublishRequiresInstallation() {
        let driver = VirtualAudioDriver()
        let state = AudioEngineState(isRunning: true)

        XCTAssertThrowsError(try driver.publish(state: state)) { error in
            XCTAssertEqual(error as? VirtualAudioDriverError, .notInstalled)
        }
    }

    func testPublishRequiresRunningAudioEngine() {
        let driver = VirtualAudioDriver()
        driver.install()

        let stoppedState = AudioEngineState(isRunning: false)

        XCTAssertThrowsError(try driver.publish(state: stoppedState)) { error in
            XCTAssertEqual(error as? VirtualAudioDriverError, .audioEngineNotRunning)
        }
    }

    func testPublishRunningStateSucceeds() throws {
        let driver = VirtualAudioDriver()
        driver.install()

        let runningState = AudioEngineState(
            isRunning: true,
            meters: AudioMeterState(pianoLevel: 0.5, masterLevel: 0.8),
            activeVelocities: [60: 100, 64: 80]
        )

        try driver.publish(state: runningState)

        XCTAssertTrue(driver.status.isPublishing)
        XCTAssertEqual(driver.status.lastMasterLevel, 0.8)
        XCTAssertNotNil(driver.currentFeed)
        XCTAssertEqual(driver.currentFeed?.activeNotes, [60, 64])
        XCTAssertNil(driver.status.lastError)
    }

    func testStopPublishingResetsState() throws {
        let driver = VirtualAudioDriver()
        driver.install()

        let runningState = AudioEngineState(isRunning: true, meters: AudioMeterState(masterLevel: 0.6))
        try driver.publish(state: runningState)

        driver.stopPublishing()

        XCTAssertFalse(driver.status.isPublishing)
        XCTAssertEqual(driver.status.lastMasterLevel, 0)
        XCTAssertNil(driver.currentFeed)
    }

    func testErrorMessageSetOnFailure() {
        let driver = VirtualAudioDriver()
        // Not installed - publish should set error
        _ = try? driver.publish(state: AudioEngineState(isRunning: true))

        XCTAssertNotNil(driver.status.lastError)
    }
}
