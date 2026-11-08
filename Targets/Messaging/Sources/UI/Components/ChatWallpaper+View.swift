import SwiftUI
import Core

/// UI presentation for the `Core` wallpaper model.
extension ChatWallpaper {
    var displayName: String {
        switch self {
        case .default: "Default"
        case .ocean: "Ocean"
        case .sunset: "Sunset"
        case .forest: "Forest"
        case .midnight: "Midnight"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .default: [Color(.systemBackground), Color(.systemBackground)]
        case .ocean: [Color(red: 0.05, green: 0.35, blue: 0.55), Color(red: 0.15, green: 0.6, blue: 0.75)]
        case .sunset: [Color(red: 0.85, green: 0.4, blue: 0.35), Color(red: 0.95, green: 0.65, blue: 0.35)]
        case .forest: [Color(red: 0.1, green: 0.35, blue: 0.2), Color(red: 0.25, green: 0.5, blue: 0.3)]
        case .midnight: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.15, green: 0.1, blue: 0.3)]
        }
    }

    @ViewBuilder
    var background: some View {
        if self == .default {
            Color(.systemBackground)
        } else {
            LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
        }
    }
}
