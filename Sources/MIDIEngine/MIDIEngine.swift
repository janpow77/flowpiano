import Foundation

public struct MIDIEvent: Equatable {
    public let note: Int
    public let velocity: Int
    public let isNoteOn: Bool
    public let channel: Int
    public let sourceDeviceID: String?

    public init(note: Int, velocity: Int, isNoteOn: Bool, channel: Int = 0, sourceDeviceID: String? = nil) {
        self.note = note
        self.velocity = velocity
        self.isNoteOn = isNoteOn
        self.channel = channel
        self.sourceDeviceID = sourceDeviceID
    }
}

extension MIDIEvent: Codable {}

public struct MIDIDevice: Equatable, Codable, Identifiable {
    public let id: String
    public var name: String
    public var isAvailable: Bool
    public var supportsVelocity: Bool

    public init(id: String, name: String, isAvailable: Bool = true, supportsVelocity: Bool = true) {
        self.id = id
        self.name = name
        self.isAvailable = isAvailable
        self.supportsVelocity = supportsVelocity
    }
}

public struct MIDIEventLogEntry: Equatable, Codable, Identifiable {
    public let id: Int
    public let event: MIDIEvent

    public init(id: Int, event: MIDIEvent) {
        self.id = id
        self.event = event
    }
}

public struct MIDIConnectionStatus: Equatable, Codable {
    public var devices: [MIDIDevice]
    public var connectedDeviceID: String?
    public var reconnectPending: Bool
    public var activeVelocities: [Int: Int]
    public var eventLog: [MIDIEventLogEntry]

    public init(
        devices: [MIDIDevice] = [],
        connectedDeviceID: String? = nil,
        reconnectPending: Bool = false,
        activeVelocities: [Int: Int] = [:],
        eventLog: [MIDIEventLogEntry] = []
    ) {
        self.devices = devices
        self.connectedDeviceID = connectedDeviceID
        self.reconnectPending = reconnectPending
        self.activeVelocities = activeVelocities
        self.eventLog = eventLog
    }

    public var connectedDevice: MIDIDevice? {
        devices.first(where: { $0.id == connectedDeviceID && $0.isAvailable })
    }

    public var isConnected: Bool {
        connectedDevice != nil && !reconnectPending
    }

    public var activeNotes: [Int] {
        activeVelocities.keys.sorted()
    }
}

public enum MIDIEngineError: Error {
    case deviceUnavailable
    case noConnectedDevice
}

public protocol MIDIEngineProtocol {
    var state: MIDIConnectionStatus { get }
    func updateAvailableDevices(_ devices: [MIDIDevice])
    func connect(to deviceID: String?) throws
    func disconnect()
    func reconnectIfPossible() -> Bool
    func receive(_ event: MIDIEvent) throws
}

public final class MIDIEngine: MIDIEngineProtocol {
    public private(set) var state: MIDIConnectionStatus
    private var nextEventID = 1

    public init(devices: [MIDIDevice] = []) {
        state = MIDIConnectionStatus(devices: devices)
        autoConnectIfNeeded()
    }

    public func updateAvailableDevices(_ devices: [MIDIDevice]) {
        state.devices = devices

        if let currentID = state.connectedDeviceID, !devices.contains(where: { $0.id == currentID && $0.isAvailable }) {
            state.reconnectPending = true
        }

        if state.reconnectPending {
            _ = reconnectIfPossible()
        } else {
            autoConnectIfNeeded()
        }
    }

    public func connect(to deviceID: String?) throws {
        guard let deviceID else {
            disconnect()
            return
        }

        guard state.devices.contains(where: { $0.id == deviceID && $0.isAvailable }) else {
            throw MIDIEngineError.deviceUnavailable
        }

        state.connectedDeviceID = deviceID
        state.reconnectPending = false
    }

    public func disconnect() {
        state.connectedDeviceID = nil
        state.reconnectPending = false
        state.activeVelocities = [:]
    }

    @discardableResult
    public func reconnectIfPossible() -> Bool {
        guard
            state.reconnectPending,
            let deviceID = state.connectedDeviceID,
            state.devices.contains(where: { $0.id == deviceID && $0.isAvailable })
        else {
            return false
        }

        state.reconnectPending = false
        return true
    }

    public func receive(_ event: MIDIEvent) throws {
        guard state.isConnected else {
            throw MIDIEngineError.noConnectedDevice
        }

        if let sourceDeviceID = event.sourceDeviceID, sourceDeviceID != state.connectedDeviceID {
            throw MIDIEngineError.noConnectedDevice
        }

        if event.isNoteOn && event.velocity > 0 {
            state.activeVelocities[event.note] = event.velocity
        } else {
            state.activeVelocities.removeValue(forKey: event.note)
        }

        state.eventLog.append(MIDIEventLogEntry(id: nextEventID, event: event))
        nextEventID += 1
        if state.eventLog.count > 32 {
            state.eventLog.removeFirst(state.eventLog.count - 32)
        }
    }

    private func autoConnectIfNeeded() {
        guard state.connectedDeviceID == nil else { return }
        state.connectedDeviceID = state.devices.first(where: \.isAvailable)?.id
        state.reconnectPending = false
    }
}
