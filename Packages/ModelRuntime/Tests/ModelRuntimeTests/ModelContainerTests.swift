import AutocompleteCore
import ModelRuntime
import XCTest

final class ModelContainerTests: XCTestCase {
    func testDirectoryNameUsesAutocompleteCoreConstant() {
        XCTAssertEqual(ModelContainer.directoryName, ApplicationSupportDirectory.name)
        XCTAssertEqual(ModelContainer.directoryName, "Libretype")
    }

    func testContainerURLUsesLibretypeDirectory() throws {
        let url = try ModelContainer.containerURL(create: false)
        XCTAssertEqual(url.lastPathComponent, "Libretype")
    }
}
