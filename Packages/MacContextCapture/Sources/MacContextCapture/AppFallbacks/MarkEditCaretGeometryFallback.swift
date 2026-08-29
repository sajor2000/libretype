import ApplicationServices
import AutocompleteCore
import CoreGraphics
import Foundation

enum MarkEditCaretGeometryFallback: AppCaretGeometryFallback {
    private static let bundleIdentifier = "app.cyan.markedit"

    static func caretGeometry(
        target: AppTarget,
        beforeCursor: String,
        afterCursor: String,
        element: AXUIElement?,
        fieldRect: CGRect?,
        current: CapturedCaretGeometry
    ) -> CapturedCaretGeometry? {
        guard target.bundleIdentifier == bundleIdentifier,
              beforeCursor.contains(where: \.isNewline) else {
            return nil
        }

        // With no glyph on the current logical line, MarkEdit exposes neither a usable caret
        // rectangle nor a nonzero character range to derive one from. Suppress until the first
        // character arrives instead of displaying the completion on a stale lower row.
        if beforeCursor.last?.isNewline == true,
           afterCursor.allSatisfy(\.isNewline) {
            return CapturedCaretGeometry(
                rect: nil,
                source: "MarkEditBlankContinuationSuppression",
                quality: .estimated
            )
        }

        guard afterCursor.isEmpty,
              current.source == "AXBoundsForRange",
              let element,
              let fieldRect,
              let currentRect = current.rect else {
            return nil
        }

        let caretLocation = (beforeCursor as NSString).length
        guard caretLocation > 0,
              let rawCurrentRect = AXCaretHelper.parameterizedRectValue(
                  for: kAXBoundsForRangeParameterizedAttribute as CFString,
                  range: NSRange(location: caretLocation, length: 0),
                  on: element
              ),
              let rawPreviousCharacterRect = AXCaretHelper.parameterizedRectValue(
                  for: kAXBoundsForRangeParameterizedAttribute as CFString,
                  range: NSRange(location: caretLocation - 1, length: 1),
                  on: element
              ),
              let corrected = correctedCaretRect(
                  currentRect: currentRect,
                  rawCurrentRect: rawCurrentRect,
                  rawPreviousCharacterRect: rawPreviousCharacterRect,
                  fieldRect: fieldRect
              ) else {
            return nil
        }

        guard abs(corrected.minX - currentRect.minX) > 1
            || abs(corrected.minY - currentRect.minY) > 1
            || abs(corrected.height - currentRect.height) > 1 else {
            return nil
        }

        return CapturedCaretGeometry(
            rect: corrected,
            source: "MarkEditPreviousCharacterBounds(AXBoundsForRange)",
            quality: .estimated
        )
    }

    /// MarkEdit's CodeMirror bridge returns the wrong zero-length range rectangle after a hard
    /// line break, while the preceding character's nonzero range remains accurate. Translate the
    /// character rectangle into the already-converted AppKit coordinate space relative to the
    /// current rectangle, avoiding assumptions about display scale or origin.
    static func correctedCaretRect(
        currentRect: CGRect,
        rawCurrentRect: CGRect,
        rawPreviousCharacterRect: CGRect,
        fieldRect: CGRect
    ) -> CGRect? {
        guard !currentRect.isEmpty,
              !rawCurrentRect.isNull,
              !rawPreviousCharacterRect.isNull,
              rawCurrentRect.height > 0,
              rawPreviousCharacterRect.height > 0 else {
            return nil
        }

        let scale = currentRect.height / rawCurrentRect.height
        guard scale.isFinite, (0.5...2.5).contains(scale) else {
            return nil
        }

        let previousCharacterRect = CGRect(
            x: currentRect.minX + (rawPreviousCharacterRect.minX - rawCurrentRect.minX) * scale,
            y: currentRect.minY + (rawCurrentRect.maxY - rawPreviousCharacterRect.maxY) * scale,
            width: rawPreviousCharacterRect.width * scale,
            height: rawPreviousCharacterRect.height * scale
        )
        let corrected = CGRect(
            x: previousCharacterRect.maxX,
            y: previousCharacterRect.minY,
            width: currentRect.width,
            height: previousCharacterRect.height
        )

        let expandedField = fieldRect.insetBy(dx: -8, dy: -8)
        guard corrected.height >= 8,
              corrected.height <= 40,
              previousCharacterRect.width <= max(80, fieldRect.width * 0.2),
              expandedField.contains(CGPoint(x: corrected.midX, y: corrected.midY)) else {
            return nil
        }
        return corrected
    }
}
