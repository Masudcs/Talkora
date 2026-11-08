import Foundation
import Observation
import Core

/// Persists the user's Appearance choice from the Profile module, following `AuthSessionStore`'s
/// UserDefaults-backed pattern. Defaults to following the system appearance.
@MainActor
@Observable
public final class ThemeStore {
    public static let shared = ThemeStore()

    public private(set) var theme: TalkoraTheme

    private let defaults: UserDefaults
    private static let themeKey = "talkora.settings.theme"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.themeKey), let theme = TalkoraTheme(rawValue: raw) {
            self.theme = theme
        } else {
            self.theme = .system
        }
    }

    /// Applies the theme immediately and persists it.
    public func setTheme(_ theme: TalkoraTheme) {
        self.theme = theme
        defaults.set(theme.rawValue, forKey: Self.themeKey)
    }
}
