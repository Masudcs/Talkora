import Foundation

/// Standard load-state envelope every feature ViewModel exposes to its View.
/// Views branch on this exhaustively using the shared LoadingView/ErrorStateView/EmptyStateView
/// components from `CommonUI`, giving every feature module identical
/// loading/empty/error UX for free.
public enum LoadableState<T> {
    case idle
    case loading
    case loaded(T)
    case empty
    case failed(AppError)

    public var value: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var error: AppError? {
        if case .failed(let error) = self { return error }
        return nil
    }
}
