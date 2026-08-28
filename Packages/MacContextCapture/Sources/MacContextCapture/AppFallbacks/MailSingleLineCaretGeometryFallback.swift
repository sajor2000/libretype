import AppKit
import ApplicationServices
import AutocompleteCore
import CoreGraphics

enum MailSingleLineCaretGeometryFallback: AppCaretGeometryFallback {
    enum FieldKind: Equatable {
        case search
        case subject

        var textInset: CGFloat {
            switch self {
            case .search: 32
            case .subject: 0
            }
        }

        var sourceLabel: String {
            switch self {
            case .search: "MailSearchFieldEstimate"
            case .subject: "MailSubjectFieldEstimate"
            }
        }
    }

    private static let fieldFont = NSFont.systemFont(ofSize: 13)

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
        let identifier = element.flatMap {
            AXCaretHelper.stringValue(for: kAXIdentifierAttribute as CFString, on: $0)
        }

        guard target.bundleIdentifier == MailComposeTextContext.bundleIdentifier,
              let fieldRect,
              let currentRect = current.rect,
              current.quality == .estimated,
              let kind = fieldKind(
                  role: role,
                  subrole: subrole,
                  identifier: identifier,
                  windowTitle: target.windowTitle,
                  fieldHeight: fieldRect.height
              ),
              fieldRect.width >= 120,
              currentRect.width <= 8,
              (12...32).contains(currentRect.height),
              currentRect.intersects(fieldRect) else {
            return nil
        }

        let corrected = correctedCaretRect(
            kind: kind,
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
            source: "\(kind.sourceLabel)(\(current.source ?? "unknown"))",
            quality: .estimated
        )
    }

    static func fieldKind(
        role: String?,
        subrole: String?,
        identifier: String?,
        windowTitle: String?,
        fieldHeight: CGFloat
    ) -> FieldKind? {
        if (28...60).contains(fieldHeight),
           role == "AXSearchField"
            || subrole == "AXSearchField"
            || windowTitle?.hasPrefix("Searching") == true {
            return .search
        }
        if (12...28).contains(fieldHeight),
           identifier == "Mail.subjectField" {
            return .subject
        }
        return nil
    }

    static func correctedCaretRect(
        kind: FieldKind,
        beforeCursor: String,
        fieldRect: CGRect,
        currentRect: CGRect
    ) -> CGRect {
        let textWidth = (beforeCursor as NSString).size(withAttributes: [.font: fieldFont]).width
        let x = min(fieldRect.maxX, fieldRect.minX + kind.textInset + textWidth)
        let y = kind == .search
            ? fieldRect.midY - currentRect.height / 2
            : currentRect.minY
        return CGRect(x: x, y: y, width: currentRect.width, height: currentRect.height)
    }
}
