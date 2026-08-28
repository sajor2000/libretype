import AppKit
import ApplicationServices
import AutocompleteCore
import CoreGraphics

enum WordSearchCaretGeometryFallback: AppCaretGeometryFallback {
    private static let bundleIdentifier = "com.microsoft.Word"
    private static let searchFont = NSFont.systemFont(ofSize: 13)
    private static let textInset: CGFloat = 25

    static func caretGeometry(
        target: AppTarget,
        beforeCursor: String,
        afterCursor: String,
        element: AXUIElement?,
        fieldRect: CGRect?,
        current: CapturedCaretGeometry
    ) -> CapturedCaretGeometry? {
        let role = element.flatMap {
            AXCaretHelper.stringValue(for: kAXRoleAttribute as CFString, on: $0)
        }
        let subrole = element.flatMap {
            AXCaretHelper.stringValue(for: kAXSubroleAttribute as CFString, on: $0)
        }
        guard target.bundleIdentifier == bundleIdentifier,
              role == "AXSearchField" || subrole == "AXSearchField",
              let fieldRect,
              (22...44).contains(fieldRect.height),
              fieldRect.width >= 120,
              let currentRect = current.rect,
              currentRect.width <= 8,
              currentRect.intersects(fieldRect) else {
            return nil
        }

        let corrected = correctedCaretRect(
            beforeCursor: beforeCursor,
            fieldRect: fieldRect,
            currentRect: currentRect
        )
        guard abs(corrected.minX - currentRect.minX) > 1
            || abs(corrected.minY - currentRect.minY) > 2 else {
            return nil
        }

        return CapturedCaretGeometry(
            rect: corrected,
            source: "WordSearchFieldEstimate(\(current.source ?? "unknown"))",
            quality: .estimated
        )
    }

    static func correctedCaretRect(
        beforeCursor: String,
        fieldRect: CGRect,
        currentRect: CGRect
    ) -> CGRect {
        let textWidth = (beforeCursor as NSString).size(withAttributes: [.font: searchFont]).width
        return CGRect(
            x: min(fieldRect.maxX, fieldRect.minX + textInset + textWidth),
            y: fieldRect.midY - currentRect.height / 2,
            width: currentRect.width,
            height: currentRect.height
        )
    }
}
