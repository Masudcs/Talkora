import SwiftUI
import Core

/// User-facing appearance preference chosen in Settings. `.system` follows the phone's light/dark
/// setting; `.light` and `.dark` override it for this app only.
public enum TalkoraTheme: String, CaseIterable, Sendable {
    case system
    case light
    case dark

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
