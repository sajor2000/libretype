import Foundation

/// Self / co-install detection for Libretype (and a still-installed KeyType).
///
/// We refuse to capture context or generate completions inside our own UI. Rules
/// (ADR-135 / U3):
/// 1. Exact match on `Bundle.main.bundleIdentifier`
/// 2. Prefix `io.github.sajor2000.libretype` (prod and `.dev`)
/// 3. Prefix `com.pattonium.keytype` so a co-installed KeyType stays excluded
/// 4. AX `appName` contains `"KeyType"` (PRODUCT_NAME stays KeyType) or `"Libretype"`
///    (`CFBundleDisplayName`)
public enum HostAppIdentity {
    public static let libretypeBundleIDPrefix = "io.github.sajor2000.libretype"
    public static let legacyKeyTypeBundleIDPrefix = "com.pattonium.keytype"

    /// Bundle-id-only check used when no AX app name is available.
    public static func isSelfBundleIdentifier(
        _ bundleIdentifier: String,
        ownBundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) -> Bool {
        let normalized = bundleIdentifier.lowercased()
        if let own = ownBundleIdentifier?.lowercased(), normalized == own {
            return true
        }
        if normalized.hasPrefix(libretypeBundleIDPrefix) {
            return true
        }
        return normalized.hasPrefix(legacyKeyTypeBundleIDPrefix)
    }

    /// Full target check including the AX app-name fallback.
    public static func isSelfTarget(
        bundleIdentifier: String,
        appName: String,
        ownBundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) -> Bool {
        if isSelfBundleIdentifier(bundleIdentifier, ownBundleIdentifier: ownBundleIdentifier) {
            return true
        }
        return appName.localizedCaseInsensitiveContains("KeyType")
            || appName.localizedCaseInsensitiveContains("Libretype")
    }
}
