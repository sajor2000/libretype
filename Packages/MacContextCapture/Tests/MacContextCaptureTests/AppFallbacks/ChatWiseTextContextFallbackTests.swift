import AppKit
import AutocompleteCore
import CoreGraphics
import XCTest
@testable import MacContextCapture

final class ChatWiseTextContextFallbackTests: XCTestCase {
    private let target = AppTarget(bundleIdentifier: "app.chatwise", appName: "ChatWise")

    func testSnapsCapturedMultilineSelectionToDocumentEnd() {
        let text = "ChatWise first line alignment\nChatWise second line alignment"
        let captured = NSRange(location: (text as NSString).length - 1, length: 0)

        let corrected = ChatWiseTextContextFallback.correctedSelectionRange(
            bundleIdentifier: target.bundleIdentifier,
            text: text,
            range: captured
        )

        XCTAssertEqual(corrected, NSRange(location: (text as NSString).length, length: 0))
    }

    func testDoesNotMoveSingleLineOrTrueMidLineSelections() {
        let singleLine = "ChatWise first line alignment"
        XCTAssertEqual(
            ChatWiseTextContextFallback.correctedSelectionRange(
                bundleIdentifier: target.bundleIdentifier,
                text: singleLine,
                range: NSRange(location: (singleLine as NSString).length - 1, length: 0)
            ),
            NSRange(location: (singleLine as NSString).length - 1, length: 0)
        )

        let multiline = "first\nsecond"
        XCTAssertEqual(
            ChatWiseTextContextFallback.correctedSelectionRange(
                bundleIdentifier: target.bundleIdentifier,
                text: multiline,
                range: NSRange(location: (multiline as NSString).length - 2, length: 0)
            ),
            NSRange(location: (multiline as NSString).length - 2, length: 0)
        )
    }

    func testCorrectsCapturedChatWiseSoftWrapGeometry() {
        let text = "ChatWise soft wrap alignment verification keeps the caret accurate when this deliberately long synthetic sentence wraps naturally onto the next visual line"
        let corrected = ChatWiseCaretGeometryFallback.caretGeometry(
            target: target,
            beforeCursor: text,
            afterCursor: "",
            element: nil,
            fieldRect: CGRect(x: 412, y: 152, width: 927, height: 53),
            current: CapturedCaretGeometry(
                rect: CGRect(x: 507.346, y: 166.027, width: 2, height: 18.486),
                source: "AXFrameEstimateAfterInvalidCaret",
                quality: .estimated
            )
        )

        XCTAssertEqual(corrected?.rect?.minX ?? 0, 655.938, accuracy: 0.01)
        XCTAssertEqual(corrected?.rect?.minY ?? 0, 157, accuracy: 0.001)
        XCTAssertEqual(corrected?.rect?.height ?? 0, 20, accuracy: 0.001)
    }

    func testKeepsNativeGeometryForShortHardWrappedLine() {
        let result = ChatWiseCaretGeometryFallback.caretGeometry(
            target: target,
            beforeCursor: "first line\nChatWise second line alignment",
            afterCursor: "",
            element: nil,
            fieldRect: CGRect(x: 412, y: 152, width: 927, height: 53),
            current: CapturedCaretGeometry(
                rect: CGRect(x: 651, y: 157, width: 2, height: 20),
                source: "AXBoundsForRange",
                quality: .exact
            )
        )

        XCTAssertNil(result)
    }

    func testDoesNotApplyRangeOrGeometryRepairsToOtherApps() {
        let text = "first line\na deliberately long final line that would otherwise wrap across the available field width"
        let captured = NSRange(location: (text as NSString).length - 1, length: 0)
        XCTAssertEqual(
            ChatWiseTextContextFallback.correctedSelectionRange(
                bundleIdentifier: "com.example.other",
                text: text,
                range: captured
            ),
            captured
        )

        XCTAssertNil(
            ChatWiseCaretGeometryFallback.caretGeometry(
                target: AppTarget(bundleIdentifier: "com.example.other", appName: "Other"),
                beforeCursor: text,
                afterCursor: "",
                element: nil,
                fieldRect: CGRect(x: 100, y: 100, width: 400, height: 60),
                current: CapturedCaretGeometry(rect: nil, source: nil, quality: .estimated)
            )
        )
    }
}
