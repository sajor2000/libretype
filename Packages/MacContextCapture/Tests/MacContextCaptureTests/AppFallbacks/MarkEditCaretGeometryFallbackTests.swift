import AutocompleteCore
import CoreGraphics
import XCTest
@testable import MacContextCapture

final class MarkEditCaretGeometryFallbackTests: XCTestCase {
    func testTranslatesPreviousCharacterBoundsIntoCorrectMultilineCaret() {
        let corrected = MarkEditCaretGeometryFallback.correctedCaretRect(
            currentRect: CGRect(x: 398, y: 814, width: 2, height: 18),
            rawCurrentRect: CGRect(x: 398, y: 150, width: 0, height: 18),
            rawPreviousCharacterRect: CGRect(x: 478, y: 129, width: 10, height: 19),
            fieldRect: CGRect(x: 184, y: 84, width: 1_186, height: 797)
        )

        XCTAssertEqual(corrected?.minX ?? 0, 488, accuracy: 0.001)
        XCTAssertEqual(corrected?.minY ?? 0, 834, accuracy: 0.001)
        XCTAssertEqual(corrected?.height ?? 0, 19, accuracy: 0.001)
    }

    func testHandlesPixelScaledParameterizedRectangles() {
        let corrected = MarkEditCaretGeometryFallback.correctedCaretRect(
            currentRect: CGRect(x: 398, y: 814, width: 2, height: 18),
            rawCurrentRect: CGRect(x: 796, y: 300, width: 0, height: 36),
            rawPreviousCharacterRect: CGRect(x: 956, y: 258, width: 20, height: 38),
            fieldRect: CGRect(x: 184, y: 84, width: 1_186, height: 797)
        )

        XCTAssertEqual(corrected?.minX ?? 0, 488, accuracy: 0.001)
        XCTAssertEqual(corrected?.minY ?? 0, 834, accuracy: 0.001)
        XCTAssertEqual(corrected?.height ?? 0, 19, accuracy: 0.001)
    }

    func testAcceptsZeroWidthCharacterBoundsWhenAXOmitsGlyphWidth() {
        let corrected = MarkEditCaretGeometryFallback.correctedCaretRect(
            currentRect: CGRect(x: 320, y: 792, width: 2, height: 18),
            rawCurrentRect: CGRect(x: 320, y: 172, width: 0, height: 18),
            rawPreviousCharacterRect: CGRect(x: 190, y: 129, width: 0, height: 19),
            fieldRect: CGRect(x: 184, y: 84, width: 1_186, height: 797)
        )

        XCTAssertEqual(corrected?.minX ?? 0, 190, accuracy: 0.001)
        XCTAssertEqual(corrected?.minY ?? 0, 834, accuracy: 0.001)
        XCTAssertEqual(corrected?.height ?? 0, 19, accuracy: 0.001)
    }

    func testSuppressesUnplaceableBlankContinuationLine() {
        let result = MarkEditCaretGeometryFallback.caretGeometry(
            target: AppTarget(bundleIdentifier: "app.cyan.markedit", appName: "MarkEdit"),
            beforeCursor: "MarkEdit first line\n",
            afterCursor: "\n",
            element: nil,
            fieldRect: CGRect(x: 184, y: 84, width: 1_186, height: 797),
            current: CapturedCaretGeometry(
                rect: CGRect(x: 184, y: 814, width: 2, height: 18),
                source: "AXBoundsForRange",
                quality: .exact
            )
        )

        XCTAssertNotNil(result)
        XCTAssertNil(result?.rect)
        XCTAssertEqual(result?.source, "MarkEditBlankContinuationSuppression")
    }

    func testRejectsImplausibleCharacterGeometry() {
        XCTAssertNil(
            MarkEditCaretGeometryFallback.correctedCaretRect(
                currentRect: CGRect(x: 398, y: 814, width: 2, height: 18),
                rawCurrentRect: CGRect(x: 398, y: 150, width: 2, height: 18),
                rawPreviousCharacterRect: CGRect(x: 1_900, y: 129, width: 500, height: 19),
                fieldRect: CGRect(x: 184, y: 84, width: 1_186, height: 797)
            )
        )
    }

    func testDoesNotApplyOutsideMarkEditOrToSingleLineText() {
        let current = CapturedCaretGeometry(
            rect: CGRect(x: 300, y: 300, width: 2, height: 18),
            source: "AXBoundsForRange",
            quality: .exact
        )
        let field = CGRect(x: 100, y: 100, width: 800, height: 600)

        XCTAssertNil(
            MarkEditCaretGeometryFallback.caretGeometry(
                target: AppTarget(bundleIdentifier: "com.example.other", appName: "Other"),
                beforeCursor: "first\nsecond",
                afterCursor: "",
                element: nil,
                fieldRect: field,
                current: current
            )
        )
        XCTAssertNil(
            MarkEditCaretGeometryFallback.caretGeometry(
                target: AppTarget(bundleIdentifier: "app.cyan.markedit", appName: "MarkEdit"),
                beforeCursor: "single line",
                afterCursor: "",
                element: nil,
                fieldRect: field,
                current: current
            )
        )
    }
}
