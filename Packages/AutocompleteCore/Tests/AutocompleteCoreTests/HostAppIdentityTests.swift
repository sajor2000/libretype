import AutocompleteCore
import XCTest

final class HostAppIdentityTests: XCTestCase {
    func testLibretypeProdAndDevPrefixesAreSelf() {
        XCTAssertTrue(HostAppIdentity.isSelfBundleIdentifier(
            "io.github.sajor2000.libretype",
            ownBundleIdentifier: nil
        ))
        XCTAssertTrue(HostAppIdentity.isSelfBundleIdentifier(
            "io.github.sajor2000.libretype.dev",
            ownBundleIdentifier: nil
        ))
    }

    func testCoInstalledKeyTypePrefixRemainsExcluded() {
        XCTAssertTrue(HostAppIdentity.isSelfBundleIdentifier(
            "com.pattonium.KeyType",
            ownBundleIdentifier: "io.github.sajor2000.libretype"
        ))
        XCTAssertTrue(HostAppIdentity.isSelfBundleIdentifier(
            "com.pattonium.KeyType.dev",
            ownBundleIdentifier: "io.github.sajor2000.libretype"
        ))
    }

    func testOwnBundleIdentifierExactMatch() {
        XCTAssertTrue(HostAppIdentity.isSelfBundleIdentifier(
            "io.github.sajor2000.libretype.dev",
            ownBundleIdentifier: "io.github.sajor2000.libretype.dev"
        ))
    }

    func testUnrelatedBundleIsNotSelf() {
        XCTAssertFalse(HostAppIdentity.isSelfBundleIdentifier(
            "com.apple.Pages",
            ownBundleIdentifier: "io.github.sajor2000.libretype"
        ))
        XCTAssertFalse(HostAppIdentity.isSelfBundleIdentifier(
            "io.github.sajor2000.libretypehelper",
            ownBundleIdentifier: "io.github.sajor2000.libretype"
        ))
        XCTAssertFalse(HostAppIdentity.isSelfBundleIdentifier(
            "com.pattonium.keytypehelper",
            ownBundleIdentifier: "io.github.sajor2000.libretype"
        ))
    }

    func testAppNameFallbackCoversProductAndDisplayNames() {
        XCTAssertTrue(HostAppIdentity.isSelfTarget(
            bundleIdentifier: "com.example.other",
            appName: "KeyType",
            ownBundleIdentifier: "io.github.sajor2000.libretype"
        ))
        XCTAssertTrue(HostAppIdentity.isSelfTarget(
            bundleIdentifier: "com.example.other",
            appName: "Libretype Dev",
            ownBundleIdentifier: "io.github.sajor2000.libretype"
        ))
        XCTAssertFalse(HostAppIdentity.isSelfTarget(
            bundleIdentifier: "com.apple.Pages",
            appName: "Pages",
            ownBundleIdentifier: "io.github.sajor2000.libretype"
        ))
    }
}
