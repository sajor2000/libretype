import XCTest
@testable import MacContextCapture

final class AppTargetResolverTests: XCTestCase {
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
