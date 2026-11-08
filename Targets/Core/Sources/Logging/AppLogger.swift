import Foundation
import os

/// Thin wrapper over `os.Logger`, categorized per subsystem area, gated by
/// `AppEnvironment.isLoggingEnabled` (errors are always logged regardless of environment).
public struct AppLogger {
    /// Becomes the `os.Logger` category, so logs can be filtered per area in Console.
    public enum Category: String {
        case network
        case ui
        case auth
        case chat
        case data
        case general
    }

    private let logger: Logger
    private let isEnabled: Bool

    public init(category: Category, isEnabled: Bool = AppEnvironment.current.isLoggingEnabled) {
        self.logger = Logger(subsystem: "com.talkora.app", category: category.rawValue)
        self.isEnabled = isEnabled
    }

    public func debug(_ message: String) {
        guard isEnabled else { return }
        logger.debug("\(message, privacy: .public)")
    }

    public func info(_ message: String) {
        guard isEnabled else { return }
        logger.info("\(message, privacy: .public)")
    }

    public func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
