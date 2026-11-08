import Foundation

/// Which API the app talks to. `mock` is the default, so the app runs with no setup.
///
/// - `mock`: `MockAPIClient` — a stateful in-memory fake server; edits persist while the app runs.
/// - `stubbed`: the real Moya networking stack answering from the bundled `StubCatalog`
///   (static canned responses). Exercises URL building, auth headers, decoding and error mapping.
/// - `live`: the real Moya stack over the network, against `AppEnvironment.apiBaseURL`.
///
/// In `stubbed` mode, `-talkora-stub-fail` makes chosen routes fail (see `StubFailureRules`).
/// `stubbed` is available in debug builds only. Pick one with the launch argument `-talkora-backend stubbed` (Xcode scheme → Arguments),
/// or the `TALKORA_BACKEND` environment variable.
public enum APIBackend: String, Sendable {
    case mock
    case stubbed
    case live

    public static let launchArgumentKey = "talkora-backend"
    public static let environmentKey = "TALKORA_BACKEND"

    public static var current: APIBackend {
        let backend = resolve(
            launchArgument: UserDefaults.standard.string(forKey: launchArgumentKey),
            environment: ProcessInfo.processInfo.environment[environmentKey]
        )
        #if DEBUG
        return backend
        #else
        // `stubs.json` isn't bundled in release builds, so stubbed mode would answer every call with 404.
        return backend == .stubbed ? .mock : backend
        #endif
    }

    public static func resolve(launchArgument: String?, environment: String?) -> APIBackend {
        [launchArgument, environment]
            .compactMap { $0?.lowercased() }
            .compactMap(APIBackend.init(rawValue:))
            .first ?? .mock
    }
}
