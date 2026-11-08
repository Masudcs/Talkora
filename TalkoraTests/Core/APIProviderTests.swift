@testable import Talkora
import Foundation
import Moya
import XCTest
@testable import Core

final class APIProviderTests: XCTestCase {
    private struct CatalogItem: Decodable, Sendable, Equatable {
        let sku: String
        let price: Double
    }

    private struct StubTarget: APITarget {
        var baseURL: URL { URL(string: "https://api.talkora.test")! }
        var path: String { "/products" }
        var method: Moya.Method { .get }
        var task: Moya.Task { .requestPlain }
        let stubStatusCode: Int
        let stubData: Data?
    }

    private func makeBackend(isProduction: Bool = false) -> APIProvider<StubTarget> {
        APIProvider<StubTarget>(isStubbed: true, stubBehavior: .immediate, isProduction: isProduction)
    }

    private func json(_ text: String) -> Data { Data(text.utf8) }

    // MARK: - Success

    func test_request_withSuccessResponse_shouldDecodeProduct() async {
        let target = StubTarget(stubStatusCode: 200, stubData: json(#"{"sku": "BZ-204", "price": 12.5}"#))

        let result: NetworkResult<CatalogItem> = await makeBackend().request(on: target)

        guard case .success(let product) = result else { return XCTFail("Expected success") }
        XCTAssertEqual(product, CatalogItem(sku: "BZ-204", price: 12.5))
    }

    func test_request_withNoContentAndEmptyResponse_shouldSucceed() async {
        let target = StubTarget(stubStatusCode: 204, stubData: Data())

        let result: NetworkResult<EmptyResponse> = await makeBackend().request(on: target)

        guard case .success = result else { return XCTFail("Expected success") }
    }

    // MARK: - Failure messages

    func test_request_withStatus503AndNoBody_shouldReturnStandardStatusMessage() async {
        let target = StubTarget(stubStatusCode: 503, stubData: Data())

        let result: NetworkResult<CatalogItem> = await makeBackend().request(on: target)

        guard case .failure(_, let message, let code) = result else { return XCTFail("Expected failure") }
        XCTAssertEqual(code, 503)
        XCTAssertEqual(message, "(503) Service unavailable")
    }

    func test_request_withServerMessageInDevelopment_shouldShowServerMessage() async {
        let target = StubTarget(stubStatusCode: 422, stubData: json(#"{"success": false, "message": "SKU already exists"}"#))

        let result: NetworkResult<CatalogItem> = await makeBackend(isProduction: false).request(on: target)

        guard case .failure(_, let message, _) = result else { return XCTFail("Expected failure") }
        XCTAssertEqual(message, "SKU already exists")
    }

    func test_request_withServerMessageInProduction_shouldShowServerMessage() async {
        let target = StubTarget(stubStatusCode: 409, stubData: json(#"{"success": false, "message": "Cart is locked"}"#))

        let result: NetworkResult<CatalogItem> = await makeBackend(isProduction: true).request(on: target)

        guard case .failure(_, let message, _) = result else { return XCTFail("Expected failure") }
        XCTAssertEqual(message, "Cart is locked")
    }

    func test_request_withBlankServerMessageInProduction_shouldShowStandardStatusMessage() async {
        let target = StubTarget(stubStatusCode: 404, stubData: json(#"{"success": false, "message": "   "}"#))

        let result: NetworkResult<CatalogItem> = await makeBackend(isProduction: true).request(on: target)

        guard case .failure(_, let message, _) = result else { return XCTFail("Expected failure") }
        XCTAssertEqual(message, "(404) Not found")
    }

    // MARK: - Decoding

    func test_request_withMalformedBody_shouldReturnInvalidResponseFailure() async {
        let target = StubTarget(stubStatusCode: 200, stubData: json("<html>oops</html>"))

        let result: NetworkResult<CatalogItem> = await makeBackend().request(on: target)

        guard case .failure(let error, let message, let code) = result, case .objectMapping = error else {
            return XCTFail("Expected decoding failure")
        }
        XCTAssertEqual(code, 200)
        XCTAssertEqual(message, "Invalid server response. Please try again.")
    }

    // MARK: - Error callback

    func test_request_withFailure_shouldCallOnErrorWithRouteAndStatusCode() async {
        var reported: (route: String, code: Int)?
        let backend = APIProvider<StubTarget>(isStubbed: true, stubBehavior: .immediate, isProduction: false) { route, code in
            reported = (route, code)
        }
        let target = StubTarget(stubStatusCode: 500, stubData: Data())

        let _: NetworkResult<CatalogItem> = await backend.request(on: target)

        XCTAssertEqual(reported?.route, "/products")
        XCTAssertEqual(reported?.code, 500)
    }
}
