#if DEBUG
import Foundation

/// Canned HTTP responses for stubbed mode, keyed by `"METHOD /path"`, loaded from the bundled
/// `Stubs/stubs.json`. `EndpointTarget` serves them through Moya's stub mechanism, so stubbed
/// mode exercises the real request building, decoding and error mapping.
///
/// The file is generated from the mock backend's seed data — see `StubCatalogGeneratorTests`.
/// File shape: `{ "GET /users": { "status": 200, "body": [ ... ] }, ... }`.
public struct StubCatalog: Sendable {
    /// One canned response: HTTP status plus the raw JSON body.
    public struct Entry: Sendable {
        public let status: Int
        public let body: Data
    }

    /// Loaded once from the main bundle; empty (every lookup misses) if `stubs.json` is absent.
    public static let shared = StubCatalog.loadFromBundle()

    private let entries: [String: Entry]

    public init(entries: [String: Entry]) {
        self.entries = entries
    }

    /// Parses the `stubs.json` shape. A missing `status` defaults to 200 and a missing or `null` body becomes empty data.
    public init(jsonData: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: jsonData) as? [String: [String: Any]] else {
            throw StubCatalogError.invalidFormat
        }
        var entries: [String: Entry] = [:]
        for (key, value) in root {
            let status = value["status"] as? Int ?? 200
            let body: Data
            if let raw = value["body"], !(raw is NSNull) {
                body = try JSONSerialization.data(withJSONObject: raw, options: [.fragmentsAllowed])
            } else {
                body = Data()
            }
            entries[key] = Entry(status: status, body: body)
        }
        self.entries = entries
    }

    public static func loadFromBundle(_ bundle: Bundle = .main) -> StubCatalog {
        guard let url = bundle.url(forResource: "stubs", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? StubCatalog(jsonData: data) else {
            return StubCatalog(entries: [:])
        }
        return catalog
    }

    public var count: Int { entries.count }
    public var keys: [String] { entries.keys.sorted() }

    /// The stub for this request: an exact path match first, then the same route with its ids
    /// generalised (so `/users/u9` can reuse the shape recorded for `/users/u1`).
    public func entry(for endpoint: Endpoint) -> Entry? {
        entries[Self.key(method: endpoint.method, path: endpoint.path)]
            ?? entries[Self.key(method: endpoint.method, path: Self.normalized(endpoint.path))]
    }

    public static func key(method: Endpoint.Method, path: String) -> String {
        "\(method.rawValue.uppercased()) \(path)"
    }

    /// Replaces every path segment that contains a digit (an id such as `u1`, `c12`, `ch3`) with `{id}`.
    public static func normalized(_ path: String) -> String {
        let segments = path.split(separator: "/", omittingEmptySubsequences: true).map { segment in
            segment.contains(where: \.isNumber) ? "{id}" : String(segment)
        }
        return "/" + segments.joined(separator: "/")
    }
}

public enum StubCatalogError: Error {
    case invalidFormat
}
#endif
