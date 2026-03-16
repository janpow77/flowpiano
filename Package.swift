// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FlowPiano",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "FlowPianoApp", targets: ["App"]),
        .library(name: "FlowPianoCore", targets: ["FlowPianoCore"])
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                "AudioEngine",
                "Diagnostics",
                "FlowPianoCore",
                "LayoutEngine",
                "MIDIEngine",
                "Persistence",
                "Settings",
                "StudioMonitor",
                "VideoEngine"
            ],
            path: "Sources/App"
        ),
        .target(name: "VideoEngine", path: "Sources/VideoEngine"),
        .target(
            name: "AudioEngine",
            dependencies: ["MIDIEngine"],
            path: "Sources/AudioEngine",
            resources: [
                .process("Resources")
            ]
        ),
        .target(name: "MIDIEngine", path: "Sources/MIDIEngine"),
        .target(name: "NotationEngine", dependencies: ["MIDIEngine"], path: "Sources/NotationEngine"),
        .target(name: "OverlayEngine", dependencies: ["LayoutEngine", "MIDIEngine"], path: "Sources/OverlayEngine"),
        .target(name: "LayoutEngine", path: "Sources/LayoutEngine"),
        .target(
            name: "StudioMonitor",
            dependencies: ["AudioEngine", "Diagnostics", "LayoutEngine", "MIDIEngine", "NotationEngine"],
            path: "Sources/StudioMonitor"
        ),
        .target(name: "Persistence", path: "Sources/Persistence"),
        .target(name: "Settings", dependencies: ["LayoutEngine"], path: "Sources/Settings"),
        .target(
            name: "Diagnostics",
            dependencies: ["AudioEngine", "LayoutEngine", "MIDIEngine", "VideoEngine", "VirtualAudioDriver", "VirtualCameraExtension"],
            path: "Sources/Diagnostics"
        ),
        .target(name: "VirtualCameraExtension", dependencies: ["LayoutEngine", "VideoEngine"], path: "Sources/VirtualCameraExtension"),
        .target(name: "VirtualAudioDriver", dependencies: ["AudioEngine"], path: "Sources/VirtualAudioDriver"),
        .target(
            name: "FlowPianoCore",
            dependencies: [
                "AudioEngine",
                "Diagnostics",
                "LayoutEngine",
                "MIDIEngine",
                "NotationEngine",
                "OverlayEngine",
                "Persistence",
                "Settings",
                "StudioMonitor",
                "VideoEngine",
                "VirtualAudioDriver",
                "VirtualCameraExtension"
            ],
            path: "Sources/FlowPianoCore"
        ),
        .testTarget(
            name: "FlowPianoUnitTests",
            dependencies: [
                "AudioEngine",
                "Diagnostics",
                "FlowPianoCore",
                "LayoutEngine",
                "MIDIEngine",
                "NotationEngine",
                "OverlayEngine",
                "Persistence",
                "Settings",
                "StudioMonitor",
                "VideoEngine",
                "VirtualAudioDriver",
                "VirtualCameraExtension"
            ],
            path: "Tests/Unit",
            exclude: ["TargetSeparationChecklist.md"]
        ),
        .testTarget(
            name: "FlowPianoIntegrationTests",
            dependencies: ["AudioEngine", "FlowPianoCore", "LayoutEngine", "MIDIEngine", "Persistence", "Settings", "VideoEngine", "VirtualAudioDriver", "VirtualCameraExtension"],
            path: "Tests/Integration"
        ),
        .testTarget(
            name: "FlowPianoUITests",
            dependencies: ["App", "FlowPianoCore", "Persistence"],
            path: "Tests/UI"
        )
    ]
)
