import XCTest
@testable import VideoEngine

final class VideoEngineTests: XCTestCase {
    func testFallsBackToSingleCameraWhenMultiCamIsUnavailable() {
        let engine = VideoEngine(
            devices: [
                CameraDevice(id: "face", name: "Face", position: .front),
                CameraDevice(id: "keys", name: "Keys", position: .external)
            ],
            capabilities: VideoCapabilities(supportsMultiCam: false, maxActiveCameras: 1)
        )

        engine.selectCamera(id: "face", for: .main)
        engine.selectCamera(id: "keys", for: .pip)

        XCTAssertEqual(engine.state.mode, .singleCamera)
        XCTAssertNil(engine.state.assignment.pipCameraID)
        XCTAssertTrue(engine.state.warnings.contains(.multiCamUnavailable))
    }

    func testSwapCameraRolesSwapsAssignments() {
        let engine = VideoEngine(
            devices: [
                CameraDevice(id: "face", name: "Face", position: .front),
                CameraDevice(id: "keys", name: "Keys", position: .external)
            ],
            capabilities: VideoCapabilities(supportsMultiCam: true, maxActiveCameras: 2)
        )

        engine.selectCamera(id: "face", for: .main)
        engine.selectCamera(id: "keys", for: .pip)
        engine.swapCameraRoles()

        XCTAssertEqual(engine.state.assignment.mainCameraID, "keys")
        XCTAssertEqual(engine.state.assignment.pipCameraID, "face")
    }
}
