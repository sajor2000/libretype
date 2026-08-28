import AppKit
import AutocompleteCore
import CoreGraphics
import XCTest
@testable import MacContextCapture

final class OutlookCaretGeometryFallbackTests: XCTestCase {
    func testCorrectsCapturedOutlookSearchGeometry() {
        let field = CGRect(x: 150, y: 590, width: 262, height: 26)
        let current = CGRect(x: 325.151, y: 590, width: 2, height: 18)

        let corrected = OutlookCaretGeometryFallback.correctedSearchCaretRect(
            beforeCursor: "Outlook search alignment",
            fieldRect: field,
            currentRect: current
        )

        XCTAssertEqual(corrected.minX, 329.845, accuracy: 0.01)
        XCTAssertEqual(corrected.minY, 594, accuracy: 0.001)
    }

    func testCentersCapturedOutlookSubjectGeometryWithoutMovingX() {
        let field = CGRect(x: 758, y: 706, width: 479, height: 34)
        let current = CGRect(x: 937.583, y: 706, width: 2, height: 18)

        let corrected = OutlookCaretGeometryFallback.centeredCompactCaretRect(
            fieldRect: field,
            currentRect: current
        )

        XCTAssertEqual(corrected.minX, current.minX, accuracy: 0.001)
        XCTAssertEqual(corrected.minY, 714, accuracy: 0.001)
    }

    func testCorrectsCapturedOutlookBodyAcrossBlankParagraphLine() {
        let field = CGRect(x: 691, y: 134, width: 638, height: 495)
        let current = CGRect(x: 855.128, y: 451.38, width: 2, height: 18.486)
        let text = "Outlook first body line\nSecond body line alignment\n\nFinal Outlook paragraph"

        let corrected = OutlookCaretGeometryFallback.correctedBodyCaretRect(
            beforeCursor: text,
            fieldRect: field,
            currentRect: current,
            font: NSFont.systemFont(ofSize: 18)
        )

        XCTAssertEqual(corrected.minX, 877.731, accuracy: 0.01)
        XCTAssertEqual(corrected.minY, 541, accuracy: 0.001)
        XCTAssertEqual(corrected.height, 22, accuracy: 0.001)
    }

    func testRecognizesOnlyOutlookSubjectIdentifierAmongCompactFields() {
        let field = CGRect(x: 0, y: 0, width: 400, height: 34)
        XCTAssertEqual(
            OutlookCaretGeometryFallback.fieldKind(
                role: "AXTextField",
                subrole: nil,
                identifier: "subjectTextField",
                fieldRect: field
            ),
            .subject
        )
        XCTAssertNil(
            OutlookCaretGeometryFallback.fieldKind(
                role: "AXTextField",
                subrole: nil,
                identifier: "toTextField",
                fieldRect: field
            )
        )
    }

    func testRecognizesPopulatedOutlookBodyRegardlessOfAXTextSubrole() {
        XCTAssertEqual(
            OutlookCaretGeometryFallback.fieldKind(
                role: "AXDocument",
                subrole: nil,
                identifier: nil,
                fieldRect: CGRect(x: 691, y: 134, width: 638, height: 495)
            ),
            .body
        )
    }

    func testRepairsDivergentExactOutlookBodyGeometry() throws {
        let result = OutlookCaretGeometryFallback.caretGeometry(
            target: AppTarget(bundleIdentifier: "com.microsoft.Outlook", appName: "Microsoft Outlook"),
            beforeCursor: "Outlook first body line\nSecond body line alignment\n\nFinal Outlook paragraph",
            afterCursor: "signature",
            element: nil,
            fieldRect: CGRect(x: 691, y: 134, width: 638, height: 495),
            current: CapturedCaretGeometry(
                rect: CGRect(x: 855.128, y: 451.38, width: 2, height: 18.486),
                source: "AXBoundsForRange",
                quality: .exact
            )
        )

        let rect = try XCTUnwrap(result?.rect)
        XCTAssertEqual(rect.minX, 877.731, accuracy: 0.01)
        XCTAssertEqual(rect.minY, 541, accuracy: 0.001)
    }

    func testOwnsMatchingExactOutlookBodyGeometryAcrossParagraphLine() throws {
        let result = OutlookCaretGeometryFallback.caretGeometry(
            target: AppTarget(bundleIdentifier: "com.microsoft.Outlook", appName: "Microsoft Outlook"),
            beforeCursor: "Outlook first body line\nSecond body line alignment\n\nFinal Outlook paragraph",
            afterCursor: "signature",
            element: nil,
            fieldRect: CGRect(x: 691, y: 134, width: 638, height: 495),
            current: CapturedCaretGeometry(
                rect: CGRect(x: 880, y: 541, width: 2, height: 23),
                source: "AXBoundsForRange",
                quality: .exact
            )
        )

        let rect = try XCTUnwrap(result?.rect)
        XCTAssertEqual(rect.minX, 880, accuracy: 0.001)
        XCTAssertEqual(rect.minY, 541, accuracy: 0.001)
        XCTAssertEqual(result?.quality, .estimated)
    }

    func testPreservesNativeHorizontalPositionWhenOutlookSoftWrapLineIsCorrect() {
        let field = CGRect(x: 691, y: 177, width: 638, height: 452)
        let current = CGRect(x: 898, y: 585, width: 2, height: 23)
        let text = "Outlook soft wrap alignment verification keeps the caret aligned on the visually wrapped continuation line"

        let corrected = OutlookCaretGeometryFallback.resolvedBodyCaretRect(
            beforeCursor: text,
            fieldRect: field,
            currentRect: current,
            font: NSFont.systemFont(ofSize: 18)
        )

        XCTAssertEqual(corrected.minX, current.minX, accuracy: 0.001)
        XCTAssertEqual(corrected.minY, 585, accuracy: 0.001)
        XCTAssertEqual(corrected.height, 22, accuracy: 0.001)
    }

    func testDoesNotReplaceExactOutlookGeometry() {
        let result = OutlookCaretGeometryFallback.caretGeometry(
            target: AppTarget(bundleIdentifier: "com.microsoft.Outlook", appName: "Microsoft Outlook"),
            beforeCursor: "",
            afterCursor: "signature",
            element: nil,
            fieldRect: CGRect(x: 691, y: 199, width: 638, height: 430),
            current: CapturedCaretGeometry(
                rect: CGRect(x: 692, y: 607, width: 2, height: 22),
                source: "AXBoundsForRange",
                quality: .exact
            )
        )

        XCTAssertNil(result)
    }
}
