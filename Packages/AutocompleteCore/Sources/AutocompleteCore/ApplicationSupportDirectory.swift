import Foundation

/// Shared Application Support container directory name for Libretype (KTD3 / KTD10).
///
/// All runtime writers that place files under
/// `~/Library/Application Support/<name>/` must use this constant rather than a
/// hard-coded `"KeyType"` or `"Libretype"` string. There is no migration from the
/// orphaned KeyType container — see ADR-135.
public enum ApplicationSupportDirectory {
    public static let name = "Libretype"
}
