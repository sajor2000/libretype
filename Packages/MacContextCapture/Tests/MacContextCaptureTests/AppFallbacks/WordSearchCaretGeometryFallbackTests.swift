import AppKit
import AutocompleteCore
import CoreGraphics
import XCTest
@testable import MacContextCapture

final class WordSearchCaretGeometryFallbackTests: XCTestCase {
    func testCorrectsCapturedWordFindGeometry() {
        let field = CGRect(x: 979, y: 742, width: 252, height: 26)
        let current = CGRect(x: 1116, y: 742, width: 2, height: 18)

        let corrected = WordSearchCaretGeometryFallback.correctedCaretRect(
            beforeCursor: "Word find alignment",
            fieldRect: field,
            currentRect: current
        )

        XCTAssertEqual(corrected.minX, 1125.951, accuracy: 0.01)
        XCTAssertEqual(corrected.minY, 746, accuracy: 0.001)
    }

    func testIgnoresNonSearchGeometry() {
        let result = WordSearchCaretGeometryFallback.caretGeometry(
            target: AppTarget(bundleIdentifier: "com.microsoft.Word", appName: "Microsoft Word"),
            beforeCursor: "Word body text",
            afterCursor: "",
            element: nil,
            fieldRect: CGRect(x: 172, y: -621, width: 1188, height: 1260),
            current: CapturedCaretGeometry(
                rect: CGRect(x: 500, y: 481, width: 2, height: 25),
                source: "AXBoundsForRange",
                quality: .exact
            )
        )

        XCTAssertNil(result)
    }
}
