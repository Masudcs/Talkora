@testable import Talkora
import Foundation
import XCTest
@testable import Core

/// Guards that the stubbed backend answers every call the repositories make, and exercises the
/// `-talkora-stub-fail` failure rules.
final class StubCoverageTests: XCTestCase {
    private let baseURL = URL(string: "https://stub.talkora.local")!

    private func makeStubbedAPI(failures: StubFailureRules = .none) -> RealAPIClient {
        RealAPIClient(
            baseURL: baseURL,
            tokenProvider: { "test-token" },
            isStubbed: true,
            stubBehavior: .immediate,
            stubCatalog: .loadFromBundle(),
            stubFailures: failures
        )
    }

    /// Runs the whole repository tour on the stubbed backend: any call without a usable stub fails here.
    func test_everyRepositoryCallInTheTour_isAnsweredByTheStubs() async {
        let tracker = FailureTrackingAPIClient(inner: makeStubbedAPI())

        await StubTour(api: tracker, environment: .current).run()

        XCTAssertEqual(tracker.failures, [], "These calls have no working stub — regenerate stubs.json")
        XCTAssertGreaterThan(tracker.successCount, 80, "The tour made suspiciously few calls")
    }

    /// Source-level guard: every `Endpoint(path:)` a `*Routes` enum declares must have a stub, so a new
    /// endpoint can't be added without regenerating `stubs.json`.
    func test_everyRepositoryRoute_hasAStub() throws {
        let networkDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Targets/Core/Sources/Network")
        let files = ((try? FileManager.default.contentsOfDirectory(at: networkDirectory, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.lastPathComponent.hasSuffix("Routes.swift") }
        // Not a skip: a moved folder must fail loudly instead of silently disabling this guard.
        XCTAssertFalse(files.isEmpty, "No *Routes.swift found in \(networkDirectory.path)")

        let catalog = StubCatalog.loadFromBundle()
        let pattern = try NSRegularExpression(pattern: #"Endpoint\(\s*path:\s*"([^"]+)"(?:\s*,\s*method:\s*\.(\w+))?"#)
        var missing: [String] = []
        var checked = 0

        for file in files where file.pathExtension == "swift" {
            let source = try String(contentsOf: file, encoding: .utf8)
            for match in pattern.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
                guard let pathRange = Range(match.range(at: 1), in: source) else { continue }
                // Swift interpolations like \(id) stand in for a real id.
                let path = String(source[pathRange]).replacingOccurrences(of: #"\\\([^)]*\)"#, with: "id1", options: .regularExpression)
                let method = Range(match.range(at: 2), in: source).flatMap { Endpoint.Method(rawValue: String(source[$0])) } ?? .get
                checked += 1
                if catalog.entry(for: Endpoint(path: path, method: method)) == nil {
                    missing.append("\(method.rawValue.uppercased()) \(path)  (\(file.lastPathComponent))")
                }
            }
        }

        XCTAssertGreaterThan(checked, 60, "The guard matched suspiciously few routes")
        XCTAssertEqual(missing, [], "Routes without a stub — regenerate stubs.json (see StubCatalogGeneratorTests)")
    }

    // MARK: Failure rules

    func test_failureRules_parseSpecificWildcardAndIgnoreGarbage() {
        let rules = StubFailureRules("GET /conversations=500, post /conversations/c1/messages = 400,*=503,bogus,GET /x=abc")

        XCTAssertEqual(rules.status(for: Endpoint(path: "/conversations")), 500)
        XCTAssertEqual(rules.status(for: Endpoint(path: "/conversations/c9/messages", method: .post)), 400)
        XCTAssertEqual(rules.status(for: Endpoint(path: "/wallet")), 503)
        XCTAssertNil(StubFailureRules("GET /wallet=401").status(for: Endpoint(path: "/me")))
        XCTAssertTrue(StubFailureRules("garbage").isEmpty)
    }

    func test_failureRule_500_surfacesAsServerError() async {
        let chat = ChatRepository(api: makeStubbedAPI(failures: StubFailureRules("GET /conversations=500")))

        do {
            _ = try await chat.conversations()
            XCTFail("Expected a server error")
        } catch APIError.serverError(let code) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Expected serverError, got \(error)")
        }
    }

    func test_failureRule_401_surfacesAsUnauthorized_andOtherRoutesStillWork() async throws {
        let api = makeStubbedAPI(failures: StubFailureRules("GET /wallet=401"))

        do {
            _ = try await PaymentRepository(api: api).wallet()
            XCTFail("Expected unauthorized")
        } catch APIError.unauthorized {
            // expected
        }
        let conversations = try await ChatRepository(api: api).conversations()
        XCTAssertFalse(conversations.isEmpty)
    }

    func test_failureRule_400_carriesTheServerMessage() async {
        let api = makeStubbedAPI(failures: StubFailureRules("POST /conversations/c1/messages=400"))

        do {
            _ = try await ChatRepository(api: api).sendMessage(text: "Hi", conversationId: "c1", replyToMessageId: nil)
            XCTFail("Expected an error")
        } catch let APIError.custom(message, _) {
            XCTAssertTrue(message.contains("400"), "Message was: \(message)")
        } catch {
            XCTFail("Expected APIError.custom, got \(error)")
        }
    }

    func test_wildcardRule_failsEveryRoute() async {
        let api = makeStubbedAPI(failures: StubFailureRules("*=500"))

        do {
            _ = try await UserRepository(api: api).allUsers()
            XCTFail("Expected a server error")
        } catch APIError.serverError {
            // expected
        } catch {
            XCTFail("Expected serverError, got \(error)")
        }
    }
}

/// Wraps a client and remembers every call that threw.
private final class FailureTrackingAPIClient: APIClientProtocol, @unchecked Sendable {
    private let inner: APIClientProtocol
    private let lock = NSLock()
    private var failed: [String] = []
    private var succeeded = 0

    init(inner: APIClientProtocol) {
        self.inner = inner
    }

    var failures: [String] {
        lock.lock(); defer { lock.unlock() }
        return failed
    }

    var successCount: Int {
        lock.lock(); defer { lock.unlock() }
        return succeeded
    }

    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        try await track(endpoint) { try await inner.request(endpoint) }
    }

    func requestPage<T: Decodable & Sendable>(_ endpoint: Endpoint, cursor: String?, pageSize: Int) async throws -> Page<T> {
        try await track(endpoint) { try await inner.requestPage(endpoint, cursor: cursor, pageSize: pageSize) }
    }

    func requestVoid(_ endpoint: Endpoint) async throws {
        try await track(endpoint) { try await inner.requestVoid(endpoint) }
    }

    private func track<R>(_ endpoint: Endpoint, _ call: () async throws -> R) async throws -> R {
        do {
            let result = try await call()
            lock.lock(); succeeded += 1; lock.unlock()
            return result
        } catch {
            lock.lock(); failed.append("\(endpoint.method.rawValue.uppercased()) \(endpoint.path) -> \(error)"); lock.unlock()
            throw error
        }
    }
}
