import XCTest
@testable import AudioEngine
import MIDIEngine

final class AudioEngineTests: XCTestCase {
    func testInternalPianoRespondsToMIDI() throws {
        let engine = AudioEngine()
        try engine.start()

        XCTAssertNotEqual(engine.state.runtime.pianoSoundBankSource, .unavailable)
        engine.process(MIDIEvent(note: 60, velocity: 100, isNoteOn: true))
        XCTAssertEqual(engine.state.activeNotes, [60])
        XCTAssertGreaterThan(engine.state.meters.pianoLevel, 0)

        engine.process(MIDIEvent(note: 60, velocity: 0, isNoteOn: false))
        XCTAssertEqual(engine.state.activeNotes, [])
    }

    func testExternalOnlyModeSuppressesInternalNotes() throws {
        let engine = AudioEngine()
        try engine.start()
        engine.setRoutingMode(.externalOnly)
        engine.setExternalInstrumentConnected(true)

        engine.process(MIDIEvent(note: 67, velocity: 110, isNoteOn: true))

        XCTAssertEqual(engine.state.activeNotes, [])
        XCTAssertGreaterThan(engine.state.meters.externalLevel, 0)
    }
}
