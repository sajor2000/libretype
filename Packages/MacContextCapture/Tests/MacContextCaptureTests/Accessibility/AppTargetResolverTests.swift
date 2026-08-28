import XCTest
@testable import MacContextCapture

final class AppTargetResolverTests: XCTestCase {
    func testBrowserChromeIsNotTreatedAsAWebField() {
        XCTAssertFalse(AppTargetResolver.resolvesAsWebField(
            hasWebAreaAncestor: false,
            appIsWebBacked: true,
            appIsBrowser: true
        ))
        XCTAssertTrue(AppTargetResolver.resolvesAsWebField(
            hasWebAreaAncestor: true,
            appIsWebBacked: true,
            appIsBrowser: true
        ))
        XCTAssertTrue(AppTargetResolver.resolvesAsWebField(
            hasWebAreaAncestor: false,
            appIsWebBacked: true,
            appIsBrowser: false
        ))
    }

    func testAncestorTraversalReachesDeepChromiumWebArea() {
        let match = AppTargetResolver.firstMatchingAncestor(
            from: 0,
            matches: { $0 == 20 },
            parent: { $0 + 1 }
        )

        XCTAssertEqual(match, 20)
    }

    func testAncestorTraversalRemainsBounded() {
        let match = AppTargetResolver.firstMatchingAncestor(
            from: 0,
            matches: { $0 == AppTargetResolver.ancestorTraversalLimit },
            parent: { $0 + 1 }
        )

        XCTAssertNil(match)
    }
}
