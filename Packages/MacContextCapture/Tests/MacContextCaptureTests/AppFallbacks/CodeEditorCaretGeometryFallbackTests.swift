import AutocompleteCore
import CoreGraphics
import XCTest
@testable import MacContextCapture

final class CodeEditorCaretGeometryFallbackTests: XCTestCase {
    func testDropsLineSizedVSCodeTextAreaFromOverlayClipping() {
        let target = AppTarget(bundleIdentifier: "com.microsoft.VSCode", appName: "Code")
        let lineFrame = CGRect(x: 270, y: 803, width: 203, height: 18)

        XCTAssertNil(
            CodeEditorCaretGeometryFallback.overlayFieldRect(
                target: target,
                role: "AXTextArea",
                subrole: nil,
                fieldRect: lineFrame,
                parentRect: CGRect(x: 204, y: 120, width: 852, height: 708)
            )
        )
    }

    func testPreservesCompactCodeEditorControlsAndFullEditorFrames() {
        let target = AppTarget(bundleIdentifier: "com.microsoft.VSCode", appName: "Code")
        let compactSearch = CGRect(x: 300, y: 700, width: 260, height: 24)
        let fullEditor = CGRect(x: 270, y: 120, width: 975, height: 680)

        XCTAssertEqual(
            CodeEditorCaretGeometryFallback.overlayFieldRect(
                target: target,
                role: "AXTextArea",
                subrole: nil,
                fieldRect: compactSearch,
                parentRect: CGRect(x: 300, y: 700, width: 340, height: 24)
            ),
            compactSearch
        )
        XCTAssertEqual(
            CodeEditorCaretGeometryFallback.overlayFieldRect(
                target: target,
                role: "AXTextArea",
                subrole: nil,
                fieldRect: fullEditor,
                parentRect: CGRect(x: 250, y: 100, width: 1_000, height: 720)
            ),
            fullEditor
        )
    }

    func testPreservesLineSizedTextAreaForOtherApps() {
        let frame = CGRect(x: 270, y: 803, width: 203, height: 18)

        XCTAssertEqual(
            CodeEditorCaretGeometryFallback.overlayFieldRect(
                target: AppTarget(bundleIdentifier: "com.example.other", appName: "Other"),
                role: "AXTextArea",
                subrole: nil,
                fieldRect: frame,
                parentRect: CGRect(x: 200, y: 100, width: 900, height: 700)
            ),
            frame
        )
    }

    func testPreservesLineSizedCodeEditorTextAreaWhenParentFrameIsUnavailable() {
        let frame = CGRect(x: 270, y: 803, width: 203, height: 18)

        XCTAssertEqual(
            CodeEditorCaretGeometryFallback.overlayFieldRect(
                target: AppTarget(bundleIdentifier: "com.microsoft.VSCode", appName: "Code"),
                role: "AXTextArea",
                subrole: nil,
                fieldRect: frame,
                parentRect: nil
            ),
            frame
        )
    }

    func testVSCodeLineOriginCaretIsEstimatedFromCurrentLinePrefix() {
        let field = CGRect(x: 277, y: 802, width: 975, height: 27)
        let current = CapturedCaretGeometry(
            rect: CGRect(x: 277, y: 802, width: 2, height: 27),
            source: "AXBoundsForRange",
            quality: .exact
        )

        let repaired = CodeEditorCaretGeometryFallback.caretGeometry(
            target: AppTarget(bundleIdentifier: "com.microsoft.VSCode", appName: "Code"),
            beforeCursor: "First line checks baseline alignment.\nSecond line is where the caret should sit",
            afterCursor: "",
            element: nil,
            fieldRect: field,
            current: current
        )

        XCTAssertEqual(repaired?.quality, .estimated)
        XCTAssertEqual(repaired?.source, "CodeEditorLineOriginEstimate(AXBoundsForRange)")
        XCTAssertEqual(repaired?.rect?.minY, current.rect?.minY)
        XCTAssertGreaterThan(repaired?.rect?.minX ?? 0, field.minX + 280)
    }

    func testCursorUsesSameLineOriginRepair() {
        let field = CGRect(x: 277, y: 802, width: 975, height: 27)
        let current = CapturedCaretGeometry(
            rect: CGRect(x: 278, y: 802, width: 2, height: 24),
            source: "AXBoundsForRange",
            quality: .exact
        )

        let repaired = CodeEditorCaretGeometryFallback.caretGeometry(
            target: AppTarget(bundleIdentifier: "com.todesktop.230313mzl4w4u92", appName: "Cursor"),
            beforeCursor: "Second line is where the caret should sit",
            afterCursor: "",
            element: nil,
            fieldRect: field,
            current: current
        )

        XCTAssertEqual(repaired?.quality, .estimated)
        XCTAssertGreaterThan(repaired?.rect?.minX ?? 0, field.minX + 280)
    }

    func testLineOriginCaretIsKeptWhenCurrentLineIsEmpty() {
        let field = CGRect(x: 277, y: 802, width: 975, height: 27)
        let current = CapturedCaretGeometry(
            rect: CGRect(x: 277, y: 802, width: 2, height: 27),
            source: "AXBoundsForRange",
            quality: .exact
        )

        let repaired = CodeEditorCaretGeometryFallback.caretGeometry(
            target: AppTarget(bundleIdentifier: "com.microsoft.VSCode", appName: "Code"),
            beforeCursor: "First line checks baseline alignment.\n",
            afterCursor: "",
            element: nil,
            fieldRect: field,
            current: current
        )

        XCTAssertNil(repaired)
    }

    func testLineOriginCaretRepairDoesNotApplyToOtherApps() {
        let field = CGRect(x: 277, y: 802, width: 975, height: 27)
        let current = CapturedCaretGeometry(
            rect: CGRect(x: 277, y: 802, width: 2, height: 27),
            source: "AXBoundsForRange",
            quality: .exact
        )

        let repaired = CodeEditorCaretGeometryFallback.caretGeometry(
            target: AppTarget(bundleIdentifier: "com.apple.TextEdit", appName: "TextEdit"),
            beforeCursor: "Second line is where the caret should sit",
            afterCursor: "",
            element: nil,
            fieldRect: field,
            current: current
        )

        XCTAssertNil(repaired)
    }
}
