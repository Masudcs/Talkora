@testable import Talkora
import Foundation
import XCTest
@testable import Core

/// Runs the real repositories over the real Moya stack (`RealAPIClient`), answering from the
/// bundled `stubs.json`. Guards that the stub file stays in step with the DTOs and endpoints:
/// if a DTO or route changes, regenerate it (see `StubCatalogGeneratorTests`).
final class StubbedBackendTests: XCTestCase {
    private let baseURL = URL(string: "https://stub.talkora.local")!

    private func makeAPI(token: String? = "test-token") -> RealAPIClient {
        RealAPIClient(
            baseURL: baseURL,
            tokenProvider: { token },
            isStubbed: true,
            stubBehavior: .immediate,
            stubCatalog: .loadFromBundle()
        )
    }

    func test_bundledCatalog_isLoaded() {
        let catalog = StubCatalog.loadFromBundle()
        XCTAssertGreaterThan(catalog.count, 100)
        XCTAssertTrue(catalog.keys.contains("GET /users"))
        XCTAssertTrue(catalog.keys.contains("GET /users/{id}"))
    }

    func test_users_decodeThroughRealStack() async throws {
        let users = UserRepository(api: makeAPI())

        let me = try await users.currentUser()
        let all = try await users.allUsers()

        XCTAssertFalse(me.displayName.isEmpty)
        XCTAssertFalse(all.isEmpty)
    }

    func test_unknownId_fallsBackToGenericRouteStub() async throws {
        let users = UserRepository(api: makeAPI())

        let user = try await users.user(id: "u99")

        XCTAssertFalse(user.id.isEmpty)
    }

    func test_chat_conversationsAndMessagePage_decode() async throws {
        let chat = ChatRepository(api: makeAPI())

        let conversations = try await chat.conversations()
        let page = try await chat.messages(conversationId: "c1", cursor: nil)

        XCTAssertFalse(conversations.isEmpty)
        XCTAssertFalse(page.items.isEmpty)
        XCTAssertFalse(page.hasMore)
    }

    func test_writes_returnCannedResponses() async throws {
        let chat = ChatRepository(api: makeAPI())

        let sent = try await chat.sendMessage(text: "Hi", conversationId: "c1", replyToMessageId: nil)
        try await chat.deleteMessage(messageId: sent.id, conversationId: "c1")
        let muted = try await chat.setMuted(true, for: "c1")

        XCTAssertFalse(sent.id.isEmpty)
        XCTAssertNotNil(muted)
    }

    func test_otherFeatures_decode() async throws {
        let api = makeAPI()

        let wallet = try await PaymentRepository(api: api).wallet()
        let bots = try await BotRepository(api: api).allBots()
        let calls = try await CallRepository(api: api).callHistory()
        let stories = try await StoryRepository(api: api).activeStories()
        let channels = try await ChannelRepository(api: api, userRepository: UserRepository(api: api)).allChannels()
        let blocked = try await PrivacyRepository(api: api).blockedUsers()
        let pinEnabled = try await AuthRepository(api: api, environment: .current).isAppLockEnabled()

        XCTAssertGreaterThanOrEqual(wallet.balance, 0)
        XCTAssertFalse(bots.isEmpty)
        XCTAssertFalse(calls.isEmpty)
        XCTAssertFalse(stories.isEmpty)
        XCTAssertFalse(channels.isEmpty)
        _ = blocked
        _ = pinEnabled
    }

    func test_endpointWithoutStub_throwsNotFound() async {
        let api = makeAPI()

        do {
            let _: UserDTO = try await api.request(Endpoint(path: "/does-not-exist"))
            XCTFail("Expected APIError.notFound")
        } catch APIError.notFound {
            // expected
        } catch {
            XCTFail("Expected APIError.notFound, got \(error)")
        }
    }

    func test_authenticatedEndpoint_withoutToken_throwsUnauthorized() async {
        let api = makeAPI(token: nil)

        do {
            let _: UserDTO = try await api.request(Endpoint(path: "/me"))
            XCTFail("Expected APIError.unauthorized")
        } catch APIError.unauthorized {
            // expected
        } catch {
            XCTFail("Expected APIError.unauthorized, got \(error)")
        }
    }

    func test_containerInStubbedMode_resolvesWorkingRepositories() async throws {
        let api = APIClientProvider.makeAPIClient(for: .stubbed, environment: .current)

        let conversations = try await ChatRepository(api: api).conversations()

        XCTAssertFalse(conversations.isEmpty)
    }
}

final class StubCatalogUnitTests: XCTestCase {
    func test_normalized_replacesSegmentsContainingDigits() {
        XCTAssertEqual(StubCatalog.normalized("/conversations/c12/messages"), "/conversations/{id}/messages")
        XCTAssertEqual(StubCatalog.normalized("/users/u1"), "/users/{id}")
        XCTAssertEqual(StubCatalog.normalized("/auth/otp/request"), "/auth/otp/request")
    }

    func test_entry_prefersExactPathOverGeneric() throws {
        let json = #"{"GET /users/u1":{"status":200,"body":{"id":"exact"}},"GET /users/{id}":{"status":200,"body":{"id":"generic"}}}"#
        let catalog = try StubCatalog(jsonData: Data(json.utf8))

        let exact = catalog.entry(for: Endpoint(path: "/users/u1"))
        let generic = catalog.entry(for: Endpoint(path: "/users/u7"))

        XCTAssertEqual(String(data: exact?.body ?? Data(), encoding: .utf8)?.contains("exact"), true)
        XCTAssertEqual(String(data: generic?.body ?? Data(), encoding: .utf8)?.contains("generic"), true)
    }

    func test_entry_nullBody_isEmptyData() throws {
        let catalog = try StubCatalog(jsonData: Data(#"{"POST /x":{"status":204,"body":null}}"#.utf8))

        let entry = catalog.entry(for: Endpoint(path: "/x", method: .post))

        XCTAssertEqual(entry?.status, 204)
        XCTAssertEqual(entry?.body, Data())
    }

    func test_entry_missing_isNil() {
        XCTAssertNil(StubCatalog(entries: [:]).entry(for: Endpoint(path: "/nope")))
    }
}

final class APIBackendTests: XCTestCase {
    func test_resolve_defaultsToMock() {
        XCTAssertEqual(APIBackend.resolve(launchArgument: nil, environment: nil), .mock)
        XCTAssertEqual(APIBackend.resolve(launchArgument: "nonsense", environment: nil), .mock)
    }

    func test_resolve_launchArgumentWinsOverEnvironment() {
        XCTAssertEqual(APIBackend.resolve(launchArgument: "stubbed", environment: "live"), .stubbed)
        XCTAssertEqual(APIBackend.resolve(launchArgument: nil, environment: "LIVE"), .live)
    }
}
