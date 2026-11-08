import XCTest
@testable import Talkora
@testable import Core

final class EndpointBodyTests: XCTestCase {
    func test_body_flattensToMockParameters() {
        let endpoint = ChatRoutes.createGroup(title: "Team", description: nil, memberIds: ["u1", "u2"]).endpoint
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.query, ["title": "Team", "memberIds": "u1,u2"])
    }

    func test_body_flattensBoolsAndNumbers() {
        let settings = ChatRoutes.updateSettings(conversationId: "c1", readReceiptsEnabled: true, disappearingSeconds: 60).endpoint
        XCTAssertEqual(settings.query, ["readReceiptsEnabled": "true", "disappearingSeconds": "60"])
        XCTAssertEqual(PaymentRoutes.topUp(amount: 25).endpoint.query, ["amount": "25"])
        XCTAssertEqual(PaymentRoutes.respond(transactionId: "t1", accept: false).endpoint.query, ["accept": "false"])
    }

    func test_body_omitsNilAndEmptyOptionals() {
        let transfer = PaymentRoutes.sendMoney(toUserId: "u2", amount: 5, note: "", conversationId: nil).endpoint
        XCTAssertEqual(transfer.query, ["toUserId": "u2", "amount": "5"])
        XCTAssertTrue(AuthRoutes.setAppLockPIN(nil).endpoint.query.isEmpty)
    }

    func test_body_isSentAsTypedJSON() throws {
        let body = try XCTUnwrap(ChatRoutes.updateSettings(conversationId: "c1", readReceiptsEnabled: true, disappearingSeconds: 60).endpoint.body)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body.json) as? [String: Any])
        XCTAssertEqual(json["readReceiptsEnabled"] as? Bool, true)
        XCTAssertEqual(json["disappearingSeconds"] as? Int, 60)
    }

    func test_getRoutes_haveNoBody() {
        XCTAssertNil(ChatRoutes.conversations.endpoint.body)
        XCTAssertNil(SearchRoutes.global(text: "hi", filter: MessageSearchFilter()).endpoint.body)
    }
}
