import FlowPianoCore
import Foundation
import MIDIEngine
import VideoEngine

#if os(macOS) && canImport(AVFoundation)
import AVFoundation
#endif

#if os(macOS) && canImport(CoreMIDI)
import CoreMIDI
#endif

@MainActor
final class FlowPianoPlatformBridge {
    private let coordinator: FlowPianoSessionCoordinator
    var onSnapshotChange: (() -> Void)?

    #if os(macOS) && canImport(AVFoundation)
    private var cameraConnectedObserver: NSObjectProtocol?
    private var cameraDisconnectedObserver: NSObjectProtocol?
    #endif

    #if os(macOS) && canImport(CoreMIDI)
    private var midiMonitor: MIDILiveMonitor?
    #endif

    init(coordinator: FlowPianoSessionCoordinator) {
        self.coordinator = coordinator
    }

    func start() {
        refreshPermissions()
        refreshHardwareSnapshot()
        installCameraObservers()
        installMIDIMonitor()
        try? coordinator.startSession()
        onSnapshotChange?()
    }

    func refreshHardwareSnapshot() {
        refreshPermissions()
        refreshVideoDevices()
        refreshVirtualDeviceInstallStatus()
        #if os(macOS) && canImport(CoreMIDI)
        midiMonitor?.refreshDevices()
        #endif
        onSnapshotChange?()
    }

    func requestPermissions() {
        #if os(macOS) && canImport(AVFoundation)
        Task { @MainActor in
            let cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
            let microphoneGranted = await AVCaptureDevice.requestAccess(for: .audio)
            coordinator.setPermissions(
                cameraGranted: cameraGranted,
                microphoneGranted: microphoneGranted,
                audioOutputGranted: true
            )
            onSnapshotChange?()
        }
        #endif
    }

    private func refreshPermissions() {
        #if os(macOS) && canImport(AVFoundation)
        let cameraGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        let microphoneGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        coordinator.setPermissions(
            cameraGranted: cameraGranted,
            microphoneGranted: microphoneGranted,
            audioOutputGranted: true
        )
        #endif
    }

    private func refreshVideoDevices() {
        #if os(macOS) && canImport(AVFoundation)
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        )
        let devices = discoverySession.devices.map { device in
            CameraDevice(
                id: device.uniqueID,
                name: device.localizedName,
                position: cameraPosition(for: device.position),
                isAvailable: device.isConnected,
                supportsHighResolution: !device.formats.isEmpty
            )
        }

        // macOS does not support AVCaptureMultiCamSession; use multiple inputs
        // on a single AVCaptureSession instead. Report multi-cam as supported
        // when more than one camera is discovered.
        let hasMultipleCameras = devices.count >= 2
        coordinator.updateAvailableCameras(
            devices,
            capabilities: VideoCapabilities(
                supportsMultiCam: hasMultipleCameras,
                maxActiveCameras: hasMultipleCameras ? 2 : 1
            )
        )
        #endif
    }

    private func refreshVirtualDeviceInstallStatus() {
        coordinator.setVirtualDevicesInstalled(
            cameraInstalled: VirtualDeviceLocator.isVirtualCameraInstalled,
            audioInstalled: VirtualDeviceLocator.isVirtualAudioInstalled
        )
    }

    private func installCameraObservers() {
        #if os(macOS) && canImport(AVFoundation)
        cameraConnectedObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureDeviceWasConnected,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshHardwareSnapshot()
        }

        cameraDisconnectedObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureDeviceWasDisconnected,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshHardwareSnapshot()
        }
        #endif
    }

    private func installMIDIMonitor() {
        #if os(macOS) && canImport(CoreMIDI)
        let monitor = MIDILiveMonitor()
        monitor.onDevicesChanged = { [weak self] devices in
            self?.coordinator.updateAvailableMIDIInputs(devices)
            self?.onSnapshotChange?()
        }
        monitor.onMIDIEvent = { [weak self] event in
            try? self?.coordinator.receiveMIDIEvent(event)
            self?.onSnapshotChange?()
        }
        midiMonitor = monitor
        midiMonitor?.refreshDevices()
        #endif
    }

    #if os(macOS) && canImport(AVFoundation)
    private func cameraPosition(for position: AVCaptureDevice.Position) -> CameraPosition {
        switch position {
        case .front:
            return .front
        case .back:
            return .rear
        case .unspecified:
            return .external
        @unknown default:
            return .unknown
        }
    }
    #endif
}

private enum VirtualDeviceLocator {
    static var isVirtualCameraInstalled: Bool {
        let candidates = [
            "/Library/CoreMediaIO/Plug-Ins/DAL/FlowPianoVirtualCamera.plugin",
            "/Library/SystemExtensions/com.example.FlowPiano.VirtualCameraExtension.systemextension",
            "\(NSHomeDirectory())/Library/SystemExtensions/com.example.FlowPiano.VirtualCameraExtension.systemextension"
        ]

        return candidates.contains(where: { FileManager.default.fileExists(atPath: $0) })
    }

    static var isVirtualAudioInstalled: Bool {
        let candidates = [
            "/Library/Audio/Plug-Ins/HAL/FlowPianoVirtualAudio.driver",
            "/Library/SystemExtensions/com.example.FlowPiano.VirtualAudioDriver.systemextension",
            "\(NSHomeDirectory())/Library/SystemExtensions/com.example.FlowPiano.VirtualAudioDriver.systemextension"
        ]

        return candidates.contains(where: { FileManager.default.fileExists(atPath: $0) })
    }
}

#if os(macOS) && canImport(CoreMIDI)
private final class MIDILiveMonitor {
    private var client = MIDIClientRef()
    private var inputPort = MIDIPortRef()
    private var connectedSources: [Int32: MIDIEndpointRef] = [:]

    var onDevicesChanged: (([MIDIDevice]) -> Void)?
    var onMIDIEvent: ((MIDIEvent) -> Void)?

    init() {
        MIDIClientCreateWithBlock("FlowPiano MIDI Client" as CFString, &client) { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshDevices()
            }
        }

        MIDIInputPortCreateWithBlock(client, "FlowPiano MIDI Input" as CFString, &inputPort) { [weak self] packetList, sourceContext in
            self?.handle(packetList: packetList, sourceContext: sourceContext)
        }
    }

    deinit {
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
        }
        if client != 0 {
            MIDIClientDispose(client)
        }
    }

    func refreshDevices() {
        var devices: [MIDIDevice] = []
        var liveSourceIDs = Set<Int32>()
        let sourceCount = MIDIGetNumberOfSources()

        for index in 0..<sourceCount {
            let source = MIDIGetSource(index)
            guard source != 0 else { continue }

            let uniqueID = midiIntProperty(object: source, property: kMIDIPropertyUniqueID) ?? Int32(index)
            liveSourceIDs.insert(uniqueID)

            let name = midiStringProperty(object: source, property: kMIDIPropertyDisplayName)
                ?? midiStringProperty(object: source, property: kMIDIPropertyName)
                ?? "MIDI Source \(index + 1)"

            devices.append(
                MIDIDevice(
                    id: String(uniqueID),
                    name: name,
                    isAvailable: true,
                    supportsVelocity: true
                )
            )

            if connectedSources[uniqueID] == nil {
                MIDIPortConnectSource(inputPort, source, UnsafeMutableRawPointer(bitPattern: Int(uniqueID)))
                connectedSources[uniqueID] = source
            }
        }

        let disconnectedSourceIDs = connectedSources.keys.filter { !liveSourceIDs.contains($0) }
        for uniqueID in disconnectedSourceIDs {
            guard let source = connectedSources[uniqueID] else { continue }
            MIDIPortDisconnectSource(inputPort, source)
            connectedSources.removeValue(forKey: uniqueID)
        }

        onDevicesChanged?(devices.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
    }

    private func handle(packetList: UnsafePointer<MIDIPacketList>, sourceContext: UnsafeMutableRawPointer?) {
        let sourceID = sourceContext.map { String(Int(bitPattern: $0)) }
        var packet = packetList.pointee.packet

        for _ in 0..<packetList.pointee.numPackets {
            let packetLength = Int(packet.length)
            let bytes = withUnsafeBytes(of: packet.data) { rawBuffer in
                Array(rawBuffer.prefix(packetLength))
            }

            emitEvents(from: bytes, sourceID: sourceID)
            packet = MIDIPacketNext(&packet).pointee
        }
    }

    private func emitEvents(from bytes: [UInt8], sourceID: String?) {
        var index = 0
        var runningStatus: UInt8?

        while index < bytes.count {
            let currentByte = bytes[index]
            let status: UInt8

            if currentByte & 0x80 != 0 {
                status = currentByte
                runningStatus = currentByte
                index += 1
            } else if let rememberedStatus = runningStatus {
                status = rememberedStatus
            } else {
                index += 1
                continue
            }

            switch status & 0xF0 {
            case 0x80, 0x90:
                guard index + 1 < bytes.count else { return }
                let note = Int(bytes[index])
                let velocity = Int(bytes[index + 1])
                index += 2

                let isNoteOn = (status & 0xF0) == 0x90 && velocity > 0
                let event = MIDIEvent(
                    note: note,
                    velocity: velocity,
                    isNoteOn: isNoteOn,
                    channel: Int(status & 0x0F),
                    sourceDeviceID: sourceID
                )
                DispatchQueue.main.async { [onMIDIEvent] in
                    onMIDIEvent?(event)
                }
            case 0xA0, 0xB0, 0xE0:
                index += 2
            case 0xC0, 0xD0:
                index += 1
            case 0xF0:
                while index < bytes.count && bytes[index] != 0xF7 {
                    index += 1
                }
                if index < bytes.count {
                    index += 1
                }
            default:
                break
            }
        }
    }

    private func midiStringProperty(object: MIDIObjectRef, property: CFString) -> String? {
        var unmanagedValue: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(object, property, &unmanagedValue)
        guard status == noErr else { return nil }
        return unmanagedValue?.takeRetainedValue() as String?
    }

    private func midiIntProperty(object: MIDIObjectRef, property: CFString) -> Int32? {
        var value: Int32 = 0
        let status = MIDIObjectGetIntegerProperty(object, property, &value)
        guard status == noErr else { return nil }
        return value
    }
}
#endif
