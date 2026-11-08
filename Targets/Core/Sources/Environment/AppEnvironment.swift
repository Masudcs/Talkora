import Foundation

/// Identifies which backend/environment the running app is configured for.
/// Sourced from build-setting-injected `Info.plist` values — see `Talkora/Configuration/*.xcconfig`.
public enum EnvironmentName: String, Sendable {
    case development
    case staging
    case production
}

/// Strongly-typed, read-once snapshot of the environment the app was built for.
/// This is the ONLY place in the codebase that should read `Bundle.main.infoDictionary`
/// or branch on `#if DEBUG` for environment purposes — everything else consumes `AppEnvironment.current`.
public struct AppEnvironment: Sendable {
    public let name: EnvironmentName
    public let apiBaseURL: URL
    public let isLoggingEnabled: Bool
    public let displayName: String

    public init(name: EnvironmentName, apiBaseURL: URL, isLoggingEnabled: Bool, displayName: String) {
        self.name = name
        self.apiBaseURL = apiBaseURL
        self.isLoggingEnabled = isLoggingEnabled
        self.displayName = displayName
    }

    /// Read once from the main bundle's Info.plist (`TalkoraEnvironmentName`, `TalkoraAPIBaseURL`, `TalkoraEnableLogging`), which the xcconfig files fill in. Missing or invalid values fall back to development defaults.
    public static let current: AppEnvironment = makeFromMainBundle()

    public static func makeFromMainBundle() -> AppEnvironment {
        let info = Bundle.main.infoDictionary ?? [:]
        let rawName = info["TalkoraEnvironmentName"] as? String ?? EnvironmentName.development.rawValue
        let name = EnvironmentName(rawValue: rawName) ?? .development
        let urlString = info["TalkoraAPIBaseURL"] as? String ?? "https://mock.talkora.local"
        let loggingString = info["TalkoraEnableLogging"] as? String ?? "YES"
        let displayName = info["CFBundleDisplayName"] as? String ?? "Talkora"

        return AppEnvironment(
            name: name,
            apiBaseURL: URL(string: urlString) ?? URL(string: "https://mock.talkora.local")!,
            isLoggingEnabled: loggingString == "YES",
            displayName: displayName
        )
    }
}

public extension AppEnvironment {
    /// Simulated mock-network tuning per environment. Only `MockAPIClient` reads this; the stubbed
    /// and live backends ignore it. It exists purely to make the mock layer behave
    /// realistically differently per build (fast/clean in Dev, flaky-on-purpose in Staging).
    public var mockLatencyRange: ClosedRange<Double> {
        switch name {
        case .development: 0.0...0.15
        case .staging: 0.3...0.8
        case .production: 0.1...0.35
        }
    }

    /// Probability that a mock GET request fails with a simulated network error.
    public var mockErrorInjectionRate: Double {
        switch name {
        case .development: 0.0
        case .staging: 0.08
        case .production: 0.01
        }
    }

    /// Real stories always last 24h — but waiting 24h to see one expire isn't a usable
    /// manual test. Dev/Staging accelerate the window so expiry is actually observable.
    public var storyExpiryDuration: TimeInterval {
        switch name {
        case .development: 120
        case .staging: 300
        case .production: 24 * 60 * 60
        }
    }
}
