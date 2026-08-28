import AppKit
import ApplicationServices
import AutocompleteCore
import CoreGraphics

enum XcodeFindCaretGeometryFallback: AppCaretGeometryFallback {
    private static let bundleIdentifier = "com.apple.dt.Xcode"
    private static let queryFont = NSFont.systemFont(ofSize: 11)
    private static let queryInset: CGFloat = 93

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
              (18...32).contains(fieldRect.height),
              fieldRect.width >= 400,
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
            || abs(corrected.minY - currentRect.minY) > 1 else {
            return nil
        }

        return CapturedCaretGeometry(
            rect: corrected,
            source: "XcodeFindFieldEstimate(\(current.source ?? "unknown"))",
            quality: .estimated
        )
    }

    static func correctedCaretRect(
        beforeCursor: String,
        fieldRect: CGRect,
        currentRect: CGRect
    ) -> CGRect {
        let textWidth = (beforeCursor as NSString).size(withAttributes: [.font: queryFont]).width
        return CGRect(
            x: min(fieldRect.maxX, fieldRect.minX + queryInset + textWidth),
            y: fieldRect.midY - currentRect.height / 2,
            width: currentRect.width,
            height: currentRect.height
        )
    }
}
