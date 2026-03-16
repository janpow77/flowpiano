import XCTest
@testable import MIDIEngine

final class MIDIEngineTests: XCTestCase {
    func testReconnectsDeviceWhenItReturns() throws {
        let engine = MIDIEngine(devices: [MIDIDevice(id: "keyboard", name: "Keyboard")])
        XCTAssertEqual(engine.state.connectedDeviceID, "keyboard")

        engine.updateAvailableDevices([])
        XCTAssertTrue(engine.state.reconnectPending)

        engine.updateAvailableDevices([MIDIDevice(id: "keyboard", name: "Keyboard")])

        XCTAssertTrue(engine.state.isConnected)
        XCTAssertFalse(engine.state.reconnectPending)
    }

    func testReceiveUpdatesActiveNotesAndEventLog() throws {
        let engine = MIDIEngine(devices: [MIDIDevice(id: "keyboard", name: "Keyboard")])
        try engine.connect(to: "keyboard")

        try engine.receive(MIDIEvent(note: 60, velocity: 90, isNoteOn: true, sourceDeviceID: "keyboard"))
        try engine.receive(MIDIEvent(note: 60, velocity: 0, isNoteOn: false, sourceDeviceID: "keyboard"))

        XCTAssertEqual(engine.state.activeNotes, [])
        XCTAssertEqual(engine.state.eventLog.count, 2)
    }
}
