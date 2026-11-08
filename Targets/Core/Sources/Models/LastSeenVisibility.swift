import Foundation

/// Improve: a single unified privacy hub — this and the other Module 9 settings all live
/// on one screen (`PrivacyScreen`) instead of scattered across the app.
public enum LastSeenVisibility: String, Sendable, CaseIterable {
    case everyone
    case nobody
}
