import XCTest
@testable import MacContextCapture

final class VisionTextRecognitionCoordinatorTests: XCTestCase {
    func testRejectsOverlapUntilActiveRecognitionActuallyFinishes() async throws {
        let coordinator = VisionTextRecognitionCoordinator()

        try await coordinator.begin()

        do {
            try await coordinator.begin()
            XCTFail("Expected overlapping OCR to be rejected")
        } catch let error as VisionTextRecognitionError {
            XCTAssertEqual(error, .busy)
        }

        await coordinator.finish()
        try await coordinator.begin()
        await coordinator.finish()
    }
}
