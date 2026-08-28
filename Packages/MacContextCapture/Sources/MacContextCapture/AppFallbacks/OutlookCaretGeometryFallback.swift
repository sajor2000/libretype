import AppKit
import ApplicationServices
import AutocompleteCore
import CoreGraphics

enum OutlookCaretGeometryFallback: AppCaretGeometryFallback {
    enum FieldKind: Equatable {
        case search
        case subject
        case body

        var sourceLabel: String {
            switch self {
            case .search: "OutlookSearchFieldEstimate"
            case .subject: "OutlookSubjectFieldEstimate"
            case .body: "OutlookBodyLayoutEstimate"
            }
        }
    }

    private static let bundleIdentifier = "com.microsoft.Outlook"
    private static let searchFont = NSFont.systemFont(ofSize: 13)
    private static let bodyFallbackFont = NSFont.systemFont(ofSize: 18)
    private static let searchTextInset: CGFloat = 25
    private static let bodyHorizontalCorrection: CGFloat = -5.5
    private static let axFontAttribute = NSAttributedString.Key("AXFont")
    private static let axFontNameKey = "AXFontName"
    private static let axFontSizeKey = "AXFontSize"

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
        guard target.bundleIdentifier == bundleIdentifier,
              let fieldRect,
              let currentRect = current.rect,
              let kind = fieldKind(
                  role: role,
                  subrole: subrole,
                  identifier: identifier,
                  fieldRect: fieldRect
              ),
              fieldRect.width >= 120,
              currentRect.width <= 8,
              currentRect.intersects(fieldRect) else {
            return nil
        }

        let corrected: CGRect
        var bodyFontForLayout: NSFont?
        switch kind {
        case .search:
            corrected = correctedSearchCaretRect(
                beforeCursor: beforeCursor,
                fieldRect: fieldRect,
                currentRect: currentRect
            )
        case .subject:
            corrected = centeredCompactCaretRect(fieldRect: fieldRect, currentRect: currentRect)
        case .body:
            let font = element.flatMap { bodyFont(on: $0, beforeCursor: beforeCursor) }
                ?? bodyFallbackFont
            bodyFontForLayout = font
            corrected = resolvedBodyCaretRect(
                beforeCursor: beforeCursor,
                fieldRect: fieldRect,
                currentRect: currentRect,
                font: font
            )
        }

        let shouldOwnMultilineBodyGeometry = kind == .body
            && bodyFontForLayout.map {
                bodyHasContinuationLine(
                    beforeCursor: beforeCursor,
                    fieldRect: fieldRect,
                    font: $0
                )
            } == true
        guard shouldOwnMultilineBodyGeometry
            || abs(corrected.minX - currentRect.minX) > 1
            || abs(corrected.minY - currentRect.minY) > 2
            || abs(corrected.height - currentRect.height) > 1 else {
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
        fieldRect: CGRect
    ) -> FieldKind? {
        if (22...44).contains(fieldRect.height),
           role == "AXSearchField" || subrole == "AXSearchField" {
            return .search
        }
        if (22...44).contains(fieldRect.height), identifier == "subjectTextField" {
            return .subject
        }
        if fieldRect.height >= 120 {
            return .body
        }
        return nil
    }

    static func correctedSearchCaretRect(
        beforeCursor: String,
        fieldRect: CGRect,
        currentRect: CGRect
    ) -> CGRect {
        let textWidth = (beforeCursor as NSString).size(withAttributes: [.font: searchFont]).width
        let x = min(fieldRect.maxX, fieldRect.minX + searchTextInset + textWidth)
        let centered = centeredCompactCaretRect(fieldRect: fieldRect, currentRect: currentRect)
        return CGRect(x: x, y: centered.minY, width: currentRect.width, height: currentRect.height)
    }

    static func centeredCompactCaretRect(fieldRect: CGRect, currentRect: CGRect) -> CGRect {
        CGRect(
            x: currentRect.minX,
            y: fieldRect.midY - currentRect.height / 2,
            width: currentRect.width,
            height: currentRect.height
        )
    }

    static func correctedBodyCaretRect(
        beforeCursor: String,
        fieldRect: CGRect,
        currentRect: CGRect,
        font: NSFont
    ) -> CGRect {
        let selection = NSRange(location: (beforeCursor as NSString).length, length: 0)
        let layout = AXCaretGeometryResolver.estimatedSoftWrappedCaretLayout(
            in: beforeCursor,
            selection: selection,
            availableWidth: fieldRect.width,
            font: font,
            widthBias: 1,
            unwrappedLineWidthBias: 1
        )
        let lineHeight = max(18, ceil(font.ascender - font.descender + font.leading))
        let height = min(fieldRect.height, lineHeight)
        let x = min(
            fieldRect.maxX,
            max(fieldRect.minX, fieldRect.minX + layout.xOffset + bodyHorizontalCorrection)
        )
        let estimatedY = fieldRect.maxY - CGFloat(layout.lineIndex + 1) * lineHeight
        let y = min(max(estimatedY, fieldRect.minY), fieldRect.maxY - height)
        return CGRect(x: x, y: y, width: currentRect.width, height: height)
    }

    static func resolvedBodyCaretRect(
        beforeCursor: String,
        fieldRect: CGRect,
        currentRect: CGRect,
        font: NSFont
    ) -> CGRect {
        let estimated = correctedBodyCaretRect(
            beforeCursor: beforeCursor,
            fieldRect: fieldRect,
            currentRect: currentRect,
            font: font
        )
        guard abs(estimated.minY - currentRect.minY) <= 3 else {
            return estimated
        }
        return CGRect(
            x: currentRect.minX,
            y: estimated.minY,
            width: currentRect.width,
            height: estimated.height
        )
    }

    static func bodyHasContinuationLine(
        beforeCursor: String,
        fieldRect: CGRect,
        font: NSFont
    ) -> Bool {
        let selection = NSRange(location: (beforeCursor as NSString).length, length: 0)
        return AXCaretGeometryResolver.estimatedSoftWrappedCaretLayout(
            in: beforeCursor,
            selection: selection,
            availableWidth: fieldRect.width,
            font: font,
            widthBias: 1,
            unwrappedLineWidthBias: 1
        ).lineIndex > 0
    }

    private static func bodyFont(on element: AXUIElement, beforeCursor: String) -> NSFont? {
        let cursorLocation = (beforeCursor as NSString).length
        let probeLocation = max(0, cursorLocation - 1)
        var range = CFRange(location: probeLocation, length: 1)
        guard let parameter = AXValueCreate(.cfRange, &range) else { return nil }

        var value: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXAttributedStringForRangeParameterizedAttribute as CFString,
            parameter,
            &value
        ) == .success,
            let string = value as? NSAttributedString,
            string.length > 0 else {
            return nil
        }

        if let font = string.attribute(.font, at: 0, effectiveRange: nil) as? NSFont {
            return font
        }
        guard let info = string.attribute(axFontAttribute, at: 0, effectiveRange: nil) as? [String: Any] else {
            return nil
        }
        let size = (info[axFontSizeKey] as? NSNumber).map(CGFloat.init(truncating:))
            ?? bodyFallbackFont.pointSize
        if let name = info[axFontNameKey] as? String,
           let font = NSFont(name: name, size: size) {
            return font
        }
        return NSFont.systemFont(ofSize: size)
    }
}
