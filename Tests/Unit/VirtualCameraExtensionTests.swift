import XCTest
@testable import VirtualCameraExtension
import LayoutEngine

final class VirtualCameraExtensionTests: XCTestCase {
    func testInstallAndUninstall() {
        let ext = VirtualCameraExtension()
        XCTAssertFalse(ext.status.isInstalled)

        ext.install()
        XCTAssertTrue(ext.status.isInstalled)
        XCTAssertNotNil(ext.status.publicationPath)
        XCTAssertNil(ext.status.lastError)

        ext.uninstall()
        XCTAssertFalse(ext.status.isInstalled)
        XCTAssertFalse(ext.status.isPublishing)
    }

    func testPublishRequiresInstallation() {
        let ext = VirtualCameraExtension()
        let scene = RenderScene(target: .publicOutput, layers: [
            RenderedLayer(kind: .mainCamera, frame: LayerFrame(x: 0, y: 0, width: 1920, height: 1080), zIndex: 0)
        ])

        XCTAssertThrowsError(try ext.publish(scene: scene)) { error in
            XCTAssertEqual(error as? VirtualCameraError, .notInstalled)
        }
    }

    func testPublishRequiresPublicOutputTarget() {
        let ext = VirtualCameraExtension()
        ext.install()

        let studioScene = RenderScene(target: .studioMonitor, layers: [
            RenderedLayer(kind: .mainCamera, frame: LayerFrame(x: 0, y: 0, width: 1920, height: 1080), zIndex: 0)
        ])

        XCTAssertThrowsError(try ext.publish(scene: studioScene)) { error in
            XCTAssertEqual(error as? VirtualCameraError, .invalidTarget)
        }
    }

    func testPublishRejectsForbiddenLayers() {
        let ext = VirtualCameraExtension()
        ext.install()

        let unsafeScene = RenderScene(target: .publicOutput, layers: [
            RenderedLayer(kind: .mainCamera, frame: LayerFrame(x: 0, y: 0, width: 1920, height: 1080), zIndex: 0),
            RenderedLayer(kind: .diagnostics, frame: LayerFrame(x: 0, y: 0, width: 400, height: 200), zIndex: 10)
        ])

        XCTAssertThrowsError(try ext.publish(scene: unsafeScene)) { error in
            if case .forbiddenLayers(let kinds) = error as? VirtualCameraError {
                XCTAssertTrue(kinds.contains(.diagnostics))
            } else {
                XCTFail("Expected forbiddenLayers error")
            }
        }
    }

    func testPublishValidSceneSucceeds() throws {
        let ext = VirtualCameraExtension()
        ext.install()

        let scene = RenderScene(target: .publicOutput, layers: [
            RenderedLayer(kind: .mainCamera, frame: LayerFrame(x: 0, y: 0, width: 1920, height: 1080), zIndex: 0),
            RenderedLayer(kind: .midiOverlay, frame: LayerFrame(x: 60, y: 900, width: 1800, height: 120), zIndex: 20)
        ])

        try ext.publish(scene: scene)

        XCTAssertTrue(ext.status.isPublishing)
        XCTAssertEqual(ext.status.lastPublishedLayerKinds, [.mainCamera, .midiOverlay])
        XCTAssertNotNil(ext.currentScene)
        XCTAssertNil(ext.status.lastError)
    }

    func testStopPublishingClearsState() throws {
        let ext = VirtualCameraExtension()
        ext.install()

        let scene = RenderScene(target: .publicOutput, layers: [
            RenderedLayer(kind: .mainCamera, frame: LayerFrame(x: 0, y: 0, width: 1920, height: 1080), zIndex: 0)
        ])
        try ext.publish(scene: scene)

        ext.stopPublishing()

        XCTAssertFalse(ext.status.isPublishing)
        XCTAssertNil(ext.currentScene)
    }
}
