import Foundation

public enum RenderTarget: String, Codable, CaseIterable {
    case publicOutput
    case studioMonitor
}

public struct LayerFrame: Equatable, Codable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = max(width, 1)
        self.height = max(height, 1)
    }

    public func moved(toX newX: Double, y newY: Double) -> LayerFrame {
        LayerFrame(x: newX, y: newY, width: width, height: height)
    }

    public func resized(width newWidth: Double, height newHeight: Double) -> LayerFrame {
        LayerFrame(x: x, y: y, width: newWidth, height: newHeight)
    }
}

public struct LayerVisibilityPolicy: Equatable, Codable {
    public var publicVisible: Bool
    public var studioVisible: Bool

    public init(publicVisible: Bool, studioVisible: Bool) {
        self.publicVisible = publicVisible
        self.studioVisible = studioVisible
    }
}

public enum LayerKind: String, Codable, CaseIterable {
    case mainCamera
    case pipCamera
    case midiOverlay
    case musicStaff
    case audioMeters
    case midiEventLog
    case latencyIndicator
    case diagnostics

    public var isPublicSafe: Bool {
        switch self {
        case .mainCamera, .pipCamera, .midiOverlay:
            return true
        case .musicStaff, .audioMeters, .midiEventLog, .latencyIndicator, .diagnostics:
            return false
        }
    }
}

public struct LayoutLayer: Equatable, Codable {
    public var kind: LayerKind
    public var frame: LayerFrame
    public var zIndex: Int
    public var visibility: LayerVisibilityPolicy

    public init(kind: LayerKind, frame: LayerFrame, zIndex: Int, visibility: LayerVisibilityPolicy) {
        self.kind = kind
        self.frame = frame
        self.zIndex = zIndex
        self.visibility = visibility
    }
}

public struct LayoutConfiguration: Equatable, Codable {
    public var layers: [LayoutLayer]

    public init(layers: [LayoutLayer]) {
        self.layers = layers
    }

    public static let `default` = LayoutConfiguration(
        layers: [
            LayoutLayer(kind: .mainCamera,
                        frame: .init(x: 0, y: 0, width: 1920, height: 1080),
                        zIndex: 0,
                        visibility: .init(publicVisible: true, studioVisible: true)),
            LayoutLayer(kind: .pipCamera,
                        frame: .init(x: 1420, y: 40, width: 440, height: 248),
                        zIndex: 10,
                        visibility: .init(publicVisible: true, studioVisible: true)),
            LayoutLayer(kind: .midiOverlay,
                        frame: .init(x: 60, y: 900, width: 1800, height: 120),
                        zIndex: 20,
                        visibility: .init(publicVisible: true, studioVisible: true)),
            LayoutLayer(kind: .musicStaff,
                        frame: .init(x: 60, y: 720, width: 1800, height: 140),
                        zIndex: 30,
                        visibility: .init(publicVisible: false, studioVisible: true)),
            LayoutLayer(kind: .audioMeters,
                        frame: .init(x: 1280, y: 320, width: 580, height: 90),
                        zIndex: 31,
                        visibility: .init(publicVisible: false, studioVisible: true)),
            LayoutLayer(kind: .midiEventLog,
                        frame: .init(x: 1280, y: 430, width: 580, height: 150),
                        zIndex: 32,
                        visibility: .init(publicVisible: false, studioVisible: true)),
            LayoutLayer(kind: .latencyIndicator,
                        frame: .init(x: 1280, y: 600, width: 300, height: 60),
                        zIndex: 33,
                        visibility: .init(publicVisible: false, studioVisible: true)),
            LayoutLayer(kind: .diagnostics,
                        frame: .init(x: 60, y: 40, width: 700, height: 180),
                        zIndex: 40,
                        visibility: .init(publicVisible: false, studioVisible: true)),
        ]
    )
}

public struct RenderedLayer: Equatable, Codable, Identifiable {
    public let kind: LayerKind
    public let frame: LayerFrame
    public let zIndex: Int

    public var id: String { kind.rawValue }

    public init(kind: LayerKind, frame: LayerFrame, zIndex: Int) {
        self.kind = kind
        self.frame = frame
        self.zIndex = zIndex
    }
}

public struct RenderScene: Equatable, Codable {
    public let target: RenderTarget
    public let layers: [RenderedLayer]

    public init(target: RenderTarget, layers: [RenderedLayer]) {
        self.target = target
        self.layers = layers
    }
}

public enum LayoutEngine {
    public static func visibleLayers(in configuration: LayoutConfiguration, for target: RenderTarget) -> [LayoutLayer] {
        configuration.layers.filter { layer in
            switch target {
            case .publicOutput: return layer.visibility.publicVisible
            case .studioMonitor: return layer.visibility.studioVisible
            }
        }.sorted { $0.zIndex < $1.zIndex }
    }

    public static func buildScene(in configuration: LayoutConfiguration, for target: RenderTarget) -> RenderScene {
        RenderScene(
            target: target,
            layers: visibleLayers(in: configuration, for: target).map { layer in
                RenderedLayer(kind: layer.kind, frame: layer.frame, zIndex: layer.zIndex)
            }
        )
    }

    public static func validatePublicOutput(in configuration: LayoutConfiguration) -> [LayerKind] {
        visibleLayers(in: configuration, for: .publicOutput)
            .map(\.kind)
            .filter { !$0.isPublicSafe }
    }

    public static func sanitizedForPublicOutput(_ configuration: LayoutConfiguration) -> LayoutConfiguration {
        LayoutConfiguration(
            layers: configuration.layers.map { layer in
                guard !layer.kind.isPublicSafe else { return layer }
                var sanitized = layer
                sanitized.visibility.publicVisible = false
                return sanitized
            }
        )
    }

    public static func updateFrame(for kind: LayerKind, to frame: LayerFrame, in configuration: LayoutConfiguration) -> LayoutConfiguration {
        LayoutConfiguration(
            layers: configuration.layers.map { layer in
                guard layer.kind == kind else { return layer }
                var updated = layer
                updated.frame = frame
                return updated
            }
        )
    }

    public static func moveLayer(_ kind: LayerKind, toX x: Double, y: Double, in configuration: LayoutConfiguration) -> LayoutConfiguration {
        guard let layer = configuration.layers.first(where: { $0.kind == kind }) else {
            return configuration
        }

        return updateFrame(for: kind, to: layer.frame.moved(toX: x, y: y), in: configuration)
    }

    public static func resizeLayer(_ kind: LayerKind, width: Double, height: Double, in configuration: LayoutConfiguration) -> LayoutConfiguration {
        guard let layer = configuration.layers.first(where: { $0.kind == kind }) else {
            return configuration
        }

        return updateFrame(for: kind, to: layer.frame.resized(width: width, height: height), in: configuration)
    }

    public static func swapCameraFrames(in configuration: LayoutConfiguration) -> LayoutConfiguration {
        guard
            let mainLayer = configuration.layers.first(where: { $0.kind == .mainCamera }),
            let pipLayer = configuration.layers.first(where: { $0.kind == .pipCamera })
        else {
            return configuration
        }

        return LayoutConfiguration(
            layers: configuration.layers.map { layer in
                switch layer.kind {
                case .mainCamera:
                    var updated = layer
                    updated.frame = pipLayer.frame
                    return updated
                case .pipCamera:
                    var updated = layer
                    updated.frame = mainLayer.frame
                    return updated
                default:
                    return layer
                }
            }
        )
    }
}
