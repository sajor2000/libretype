import AutocompleteCore
import CoreGraphics
import XCTest
@testable import MacContextCapture

final class MailSingleLineCaretGeometryFallbackTests: XCTestCase {
    func testCorrectsCapturedMailSearchGeometry() throws {
        let field = CGRect(x: 1_178, y: 904, width: 327, height: 38)
        let caret = CGRect(x: 1_327.304, y: 921.514, width: 2, height: 18.486)

        let result = MailSingleLineCaretGeometryFallback.caretGeometry(
            target: AppTarget(
                bundleIdentifier: "com.apple.mail",
                appName: "Mail",
                windowTitle: "Searching – All Inboxes, 27 results"
            ),
            beforeCursor: "Mail search alignment",
            afterCursor: "",
            element: nil,
            fieldRect: field,
            current: CapturedCaretGeometry(rect: caret, source: "AXFrameEstimate", quality: .estimated)
        )

        let resolved = try XCTUnwrap(result)
        let resolvedRect = try XCTUnwrap(resolved.rect)
        XCTAssertEqual(resolvedRect.midY, field.midY, accuracy: 0.001)
        XCTAssertEqual(resolvedRect.minX, 1_342.063, accuracy: 0.01)
        XCTAssertEqual(resolved.source, "MailSearchFieldEstimate(AXFrameEstimate)")
    }

    func testCorrectsCapturedMailSubjectGeometry() {
        let field = CGRect(x: 907, y: 695.5, width: 525.5, height: 18)
        let caret = CGRect(x: 1_065.152, y: 695.5, width: 2, height: 18)

        let corrected = MailSingleLineCaretGeometryFallback.correctedCaretRect(
            kind: .subject,
            beforeCursor: "Mail subject regression",
            fieldRect: field,
            currentRect: caret
        )

        XCTAssertEqual(corrected.minX, 1_046.985, accuracy: 0.01)
        XCTAssertEqual(corrected.minY, caret.minY, accuracy: 0.001)
    }

    func testRecognizesOnlyMailSubjectIdentifierAmongCompactFields() {
        XCTAssertEqual(
            MailSingleLineCaretGeometryFallback.fieldKind(
                role: "AXTextField",
                subrole: nil,
                identifier: "Mail.subjectField",
                windowTitle: "Mail subject regression",
                fieldHeight: 18
            ),
            .subject
        )
        XCTAssertNil(
            MailSingleLineCaretGeometryFallback.fieldKind(
                role: "AXTextField",
                subrole: nil,
                identifier: "Mail.toField",
                windowTitle: "Mail subject regression",
                fieldHeight: 18
            )
        )
    }

    func testDoesNotReplaceExactCaretGeometry() {
        let result = MailSingleLineCaretGeometryFallback.caretGeometry(
            target: AppTarget(bundleIdentifier: "com.apple.mail", appName: "Mail"),
            beforeCursor: "Mail search alignment",
            afterCursor: "",
            element: nil,
            fieldRect: CGRect(x: 1_178, y: 904, width: 327, height: 38),
            current: CapturedCaretGeometry(
                rect: CGRect(x: 1_342, y: 914, width: 2, height: 18),
                source: "AXBoundsForRange",
                quality: .exact
            )
        )

        XCTAssertNil(result)
    }
}
