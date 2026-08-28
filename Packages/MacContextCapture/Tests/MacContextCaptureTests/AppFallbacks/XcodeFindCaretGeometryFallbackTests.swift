import AppKit
import AutocompleteCore
import CoreGraphics
import XCTest
@testable import MacContextCapture

final class XcodeFindCaretGeometryFallbackTests: XCTestCase {
    func testCorrectsCapturedXcodeFindGeometry() {
        let field = CGRect(x: 63, y: 817, width: 674, height: 22)
        let current = CGRect(x: 208, y: 817, width: 2, height: 18)

        let corrected = XcodeFindCaretGeometryFallback.correctedCaretRect(
            beforeCursor: "Xcode find alignment",
            fieldRect: field,
            currentRect: current
        )

        XCTAssertEqual(corrected.minX, 267.096, accuracy: 0.01)
        XCTAssertEqual(corrected.minY, 819, accuracy: 0.001)
    }

    func testCorrectsCapturedXcodeReplaceGeometry() {
        let corrected = XcodeFindCaretGeometryFallback.correctedCaretRect(
            beforeCursor: "Xcode replace alignment",
            fieldRect: CGRect(x: 62, y: 793, width: 692, height: 22),
            currentRect: CGRect(x: 208, y: 793, width: 2, height: 18)
        )

        XCTAssertEqual(corrected.minX, 284.733, accuracy: 0.01)
        XCTAssertEqual(corrected.minY, 795, accuracy: 0.001)
    }

    func testDoesNotApplyToNarrowXcodeSearchFields() {
        let result = XcodeFindCaretGeometryFallback.caretGeometry(
            target: AppTarget(bundleIdentifier: "com.apple.dt.Xcode", appName: "Xcode"),
            beforeCursor: "filter",
            afterCursor: "",
            element: nil,
            fieldRect: CGRect(x: 800, y: 900, width: 220, height: 22),
            current: CapturedCaretGeometry(
                rect: CGRect(x: 850, y: 900, width: 2, height: 18),
                source: "AXBoundsForRange",
                quality: .exact
            )
        )

        XCTAssertNil(result)
    }
}
