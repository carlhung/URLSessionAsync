import XCTest
@testable import URLSessionAsync
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

fileprivate struct Model: Decodable {
    enum Sex: String, Decodable {
        case male, female
    }

    let sex: Sex
    let single: Bool
    let name: String
}

fileprivate let modelStr = """
    {
        "sex": "female",
        "single": true,
        "name": "carl"
    }
    """

final class URLSessionAsyncTests: XCTestCase {
    func testExample1() throws {

        let data = modelStr.data(using: .utf8) ?? Data()
        let modelData = try data.decodeJSON(Model.self)

        XCTAssertNotNil(modelData)
    }

    func testExample2() throws {
        let data: Model? = try modelStr.decodeJSON()

        XCTAssertNotNil(data)
    }

    func testErrorMessages() {
        XCTAssert(URLSession.URLSessionError.httpURLResponseFailure.description == "failed to cast to HTTPURLResponse")
    }
}
