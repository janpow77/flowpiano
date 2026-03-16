import XCTest
@testable import LayoutEngine

final class LayoutVisibilityTests: XCTestCase {
    func testStudioOnlyLayersAreExcludedFromPublicOutput() {
        let publicLayers = LayoutEngine.visibleLayers(in: .default, for: .publicOutput)
        XCTAssertFalse(publicLayers.contains(where: { $0.kind == .musicStaff }))
        XCTAssertFalse(publicLayers.contains(where: { $0.kind == .audioMeters }))
        XCTAssertFalse(publicLayers.contains(where: { $0.kind == .midiEventLog }))
        XCTAssertFalse(publicLayers.contains(where: { $0.kind == .latencyIndicator }))
        XCTAssertFalse(publicLayers.contains(where: { $0.kind == .diagnostics }))
    }

    func testStudioMonitorContainsLocalOnlyLayers() {
        let studioLayers = LayoutEngine.visibleLayers(in: .default, for: .studioMonitor)
        XCTAssertTrue(studioLayers.contains(where: { $0.kind == .musicStaff }))
        XCTAssertTrue(studioLayers.contains(where: { $0.kind == .audioMeters }))
        XCTAssertTrue(studioLayers.contains(where: { $0.kind == .midiEventLog }))
        XCTAssertTrue(studioLayers.contains(where: { $0.kind == .latencyIndicator }))
        XCTAssertTrue(studioLayers.contains(where: { $0.kind == .diagnostics }))
    }

    func testValidationDetectsPublicLeak() {
        let unsafeConfiguration = LayoutConfiguration(
            layers: LayoutConfiguration.default.layers.map { layer in
                guard layer.kind == .diagnostics else { return layer }
                var updated = layer
                updated.visibility.publicVisible = true
                return updated
            }
        )

        XCTAssertEqual(LayoutEngine.validatePublicOutput(in: unsafeConfiguration), [.diagnostics])
        XCTAssertEqual(LayoutEngine.validatePublicOutput(in: LayoutEngine.sanitizedForPublicOutput(unsafeConfiguration)), [])
    }
}
