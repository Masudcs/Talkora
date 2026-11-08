#if DEBUG
import Foundation

/// Makes chosen routes fail in stubbed mode, so error handling can be exercised on the real
/// networking stack (the equivalent of MyStore's `failure` / `error` stub variants).
///
/// A rule list is a comma-separated string of `METHOD /path=status`, or `*=status` for every
/// route. Paths may use real ids; an id in a rule matches any id (`/users/u1` ≙ `/users/{id}`).
///
///     -talkora-stub-fail "GET /conversations=500"
///     -talkora-stub-fail "POST /conversations/c1/messages=400,GET /wallet=401"
///     -talkora-stub-fail "*=500"
///
/// The same string can be supplied through the `TALKORA_STUB_FAIL` environment variable.
public struct StubFailureRules: Sendable {
    public static let launchArgumentKey = "talkora-stub-fail"
    public static let environmentKey = "TALKORA_STUB_FAIL"

    public static let none = StubFailureRules(rules: [])

    public static var fromLaunch: StubFailureRules {
        let spec = UserDefaults.standard.string(forKey: launchArgumentKey)
            ?? ProcessInfo.processInfo.environment[environmentKey]
            ?? ""
        return StubFailureRules(spec)
    }

    private struct Rule: Sendable {
        /// `nil` means "every route".
        let route: String?
        let status: Int
    }

    private let rules: [Rule]

    private init(rules: [Rule]) {
        self.rules = rules
    }

    public init(_ spec: String) {
        self.rules = spec
            .split(separator: ",")
            .compactMap { part -> Rule? in
                let pieces = part.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                guard pieces.count == 2, let status = Int(pieces[1]), (100...599).contains(status) else { return nil }
                if pieces[0] == "*" { return Rule(route: nil, status: status) }
                let route = pieces[0].split(separator: " ", maxSplits: 1).map { String($0) }
                guard route.count == 2 else { return nil }
                return Rule(route: "\(route[0].uppercased()) \(StubCatalog.normalized(route[1].trimmingCharacters(in: .whitespaces)))", status: status)
            }
    }

    public var isEmpty: Bool { rules.isEmpty }

    /// The status this endpoint should fail with, if any. Specific routes win over `*`.
    public func status(for endpoint: Endpoint) -> Int? {
        let key = "\(endpoint.method.rawValue.uppercased()) \(StubCatalog.normalized(endpoint.path))"
        if let specific = rules.first(where: { $0.route == key }) { return specific.status }
        return rules.first(where: { $0.route == nil })?.status
    }

    /// JSON error body in the server's `{"success": false, "message": ...}` shape.
    public static func errorBody(for status: Int) -> Data {
        let body = ServerErrorBody(success: false, message: "Stubbed \(status) failure: \(HTTPStatus.message(for: status))")
        return (try? JSONEncoder().encode(body)) ?? Data()
    }
}
#endif
