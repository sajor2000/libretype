import AutocompleteCore
import XCTest

final class ApplicationSupportDirectoryTests: XCTestCase {
    func testDirectoryNameIsLibretype() {
        XCTAssertEqual(ApplicationSupportDirectory.name, "Libretype")
    }
}
