import XCTest
@testable import OverlayEngine
import LayoutEngine
import MIDIEngine

final class OverlayEngineTests: XCTestCase {
    func testInitialStateIsVisibleWithNoKeys() {
        let engine = OverlayEngine()

        XCTAssertTrue(engine.state.isVisible)
        XCTAssertTrue(engine.state.showLabels)
        XCTAssertTrue(engine.state.activeKeys.isEmpty)
    }

    func testUpdateFromMIDIStatusPopulatesActiveKeys() {
        let engine = OverlayEngine()
        let midiStatus = MIDIConnectionStatus(
            devices: [MIDIDevice(id: "k1", name: "Keyboard")],
            connectedDeviceID: "k1",
            activeVelocities: [60: 100, 64: 80, 67: 90]
        )

        engine.update(from: midiStatus)

        XCTAssertEqual(engine.state.activeKeys.count, 3)
        XCTAssertEqual(engine.state.activeKeys.map(\.note), [60, 64, 67])
    }

    func testUpdateFromVelocitiesDirectly() {
        let engine = OverlayEngine()
        engine.update(activeVelocities: [48: 70, 55: 110])

        XCTAssertEqual(engine.state.activeKeys.count, 2)
        XCTAssertEqual(engine.state.activeKeys.first?.velocity, 70)
    }

    func testVisibilityToggle() {
        let engine = OverlayEngine()
        engine.setVisible(false)
        XCTAssertFalse(engine.state.isVisible)

        engine.setVisible(true)
        XCTAssertTrue(engine.state.isVisible)
    }

    func testShowLabelsToggle() {
        let engine = OverlayEngine()
        engine.setShowLabels(false)
        XCTAssertFalse(engine.state.showLabels)
    }

    func testFrameUpdate() {
        let engine = OverlayEngine()
        let newFrame = LayerFrame(x: 100, y: 200, width: 1600, height: 150)
        engine.setFrame(newFrame)

        XCTAssertEqual(engine.state.frame, newFrame)
    }

    func testEmptyVelocitiesClearsKeys() {
        let engine = OverlayEngine()
        engine.update(activeVelocities: [60: 100])
        XCTAssertEqual(engine.state.activeKeys.count, 1)

        engine.update(activeVelocities: [:])
        XCTAssertTrue(engine.state.activeKeys.isEmpty)
    }
}
