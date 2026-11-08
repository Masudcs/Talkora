@testable import Talkora
import Foundation
import XCTest
@testable import Core
@testable import Mock

/// Regenerates `Talkora/Resources/Stubs/stubs.json` from the mock backend's seed data.
///
/// Skipped in normal runs. To regenerate after changing fixtures or endpoints:
///
///     TEST_RUNNER_GENERATE_STUBS=1 \
///     TEST_RUNNER_STUBS_OUTPUT_PATH="$PWD/Talkora/Resources/Stubs/stubs.json" \
///     xcodebuild test -workspace Talkora.xcworkspace -scheme Talkora-Dev \
///       -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:TalkoraTests/StubCatalogGeneratorTests
///
/// It drives every repository method against a fresh `MockAPIClient`, records each real
/// response body, and writes them keyed by `"METHOD /path"`.
final class StubCatalogGeneratorTests: XCTestCase {
    func test_generateStubCatalog() async throws {
        let env = ProcessInfo.processInfo.environment
        try XCTSkipUnless(env["GENERATE_STUBS"] == "1", "Set TEST_RUNNER_GENERATE_STUBS=1 to regenerate stubs.json")
        let outputPath = try XCTUnwrap(env["STUBS_OUTPUT_PATH"], "Set TEST_RUNNER_STUBS_OUTPUT_PATH")

        let environment = AppEnvironment(name: .development, apiBaseURL: URL(string: "https://stub.talkora.local")!, isLoggingEnabled: false, displayName: "Stub")
        let recorder = RecordingAPIClient(inner: MockAPIClient(store: MockDataStore(), environment: environment))

        await StubTour(api: recorder, environment: environment).run()

        let data = try recorder.serializedCatalog()
        try data.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
        XCTAssertGreaterThan(recorder.entryCount, 50, "The tour recorded suspiciously few endpoints")
    }
}

/// Wraps an `APIClientProtocol` and records every successful response body.
final class RecordingAPIClient: APIClientProtocol, @unchecked Sendable {
    private let inner: APIClientProtocol
    private let lock = NSLock()
    private var entries: [String: [String: Any]] = [:]

    init(inner: APIClientProtocol) {
        self.inner = inner
    }

    var entryCount: Int {
        lock.lock(); defer { lock.unlock() }
        return entries.count
    }

    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let value: T = try await inner.request(endpoint)
        record(endpoint, body: Self.jsonObject(value))
        return value
    }

    func requestPage<T: Decodable & Sendable>(_ endpoint: Endpoint, cursor: String?, pageSize: Int) async throws -> Page<T> {
        let page: Page<T> = try await inner.requestPage(endpoint, cursor: cursor, pageSize: pageSize)
        // A static stub can't serve a second page, so it always reports "no more".
        record(endpoint, body: ["items": Self.jsonObject(page.items) ?? [], "hasMore": false])
        return page
    }

    func requestVoid(_ endpoint: Endpoint) async throws {
        try await inner.requestVoid(endpoint)
        record(endpoint, body: nil)
    }

    func serializedCatalog() throws -> Data {
        lock.lock(); defer { lock.unlock() }
        return try JSONSerialization.data(withJSONObject: entries, options: [.prettyPrinted, .sortedKeys])
    }

    private func record(_ endpoint: Endpoint, body: Any?) {
        let entry: [String: Any] = ["status": 200, "body": body ?? NSNull()]
        lock.lock(); defer { lock.unlock() }
        // Ids the tour itself just created (UUIDs, `ch-1A2B3C4D`) are throwaway; only the generic key is useful.
        if !Self.containsGeneratedId(endpoint.path) {
            entries[StubCatalog.key(method: endpoint.method, path: endpoint.path)] = entry
        }
        // Also under a generalised path, so ids the tour never visited still resolve (first one wins).
        let generic = StubCatalog.key(method: endpoint.method, path: StubCatalog.normalized(endpoint.path))
        if entries[generic] == nil { entries[generic] = entry }
    }

    private static func containsGeneratedId(_ path: String) -> Bool {
        path.split(separator: "/").contains { segment in
            UUID(uuidString: String(segment)) != nil
                || String(segment).range(of: "^[a-z]+-[0-9A-Fa-f]{8}$", options: .regularExpression) != nil
        }
    }

    private static func jsonObject(_ value: some Any) -> Any? {
        guard let encodable = value as? any Encodable,
              let data = try? JSONEncoder().encode(encodable) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }
}
