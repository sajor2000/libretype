import AppKit
import ApplicationServices
import AutocompleteCore
import CoreGraphics
import Foundation

enum ChatWiseTextContextFallback {
    private static let bundleIdentifier = "app.chatwise"

    /// ChatWise's multiline composer reports a collapsed AX selection one UTF-16 unit before the
    /// document end. Its first line is accurate; once a hard line break exists, the stale index
    /// leaves the final character in `afterCursor` and makes an append look like a mid-line edit.
    static func correctedSelectionRange(
        bundleIdentifier: String,
        text: String,
        range: NSRange?
    ) -> NSRange? {
        guard bundleIdentifier == self.bundleIdentifier,
              let range,
              range.location != NSNotFound,
              range.length == 0,
              text.contains(where: \.isNewline) else {
            return range
        }

        let textLength = (text as NSString).length
        guard textLength > 0, range.location == textLength - 1 else {
            return range
        }
        return NSRange(location: textLength, length: 0)
    }
}

enum ChatWiseCaretGeometryFallback: AppCaretGeometryFallback {
    private static let bundleIdentifier = "app.chatwise"
    private static let composerFont = NSFont.systemFont(ofSize: 16)
    private static let horizontalInset: CGFloat = 7
    private static let bottomRowHeight: CGFloat = 30
    private static let caretHeight: CGFloat = 20

    static func caretGeometry(
        target: AppTarget,
        beforeCursor: String,
        afterCursor: String,
        element: AXUIElement?,
        fieldRect: CGRect?,
        current: CapturedCaretGeometry
    ) -> CapturedCaretGeometry? {
        guard target.bundleIdentifier == bundleIdentifier,
              afterCursor.isEmpty,
              let fieldRect,
              fieldRect.width >= 400,
              fieldRect.height >= 40 else {
            return nil
        }

        let currentLine = beforeCursor.components(separatedBy: .newlines).last ?? beforeCursor
        let selection = NSRange(location: (currentLine as NSString).length, length: 0)
        let availableWidth = max(1, fieldRect.width - horizontalInset * 2)
        let layout = AXCaretGeometryResolver.estimatedSoftWrappedCaretLayout(
            in: currentLine,
            selection: selection,
            availableWidth: availableWidth,
            font: composerFont,
            widthBias: 1,
            unwrappedLineWidthBias: 1
        )
        guard layout.lineIndex > 0 else { return nil }

        let corrected = CGRect(
            x: min(fieldRect.maxX, fieldRect.minX + horizontalInset + layout.xOffset),
            y: fieldRect.minY + (min(bottomRowHeight, fieldRect.height) - caretHeight) / 2,
            width: current.rect?.width ?? 2,
            height: caretHeight
        )
        if let currentRect = current.rect,
           abs(corrected.minX - currentRect.minX) <= 1,
           abs(corrected.minY - currentRect.minY) <= 1,
           abs(corrected.height - currentRect.height) <= 1 {
            return nil
        }

        return CapturedCaretGeometry(
            rect: corrected,
            source: "ChatWiseSoftWrapEstimate(\(current.source ?? "unknown"))",
            quality: .estimated
        )
    }
}
