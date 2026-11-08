#if DEBUG
import Foundation

/// The state a preview-only ViewModel should show, mirroring MyStore's `isLoading` / `isError` /
/// `isEmptyView` preview flags in one value.
public enum PreviewScenario {
    case loaded
    case loading
    case empty
    case failed

    /// The error shown by the `.failed` scenario.
    public static let sampleError: AppError = GenericAppError(underlying: SampleError(), userMessage: "Something went wrong. Please try again.")

    private struct SampleError: Error {}

    /// Maps a sample list onto the matching `LoadableState` for this scenario.
    public func state<T>(_ items: [T]) -> LoadableState<[T]> {
        switch self {
        case .loaded: .loaded(items)
        case .loading: .loading
        case .empty: .empty
        case .failed: .failed(Self.sampleError)
        }
    }
}

/// The state a preview-only form ViewModel should show: what is typed, and the submit result.
public enum FormPreviewScenario {
    case empty
    case filled
    case invalid
    case submitting
    case failed
}
#endif
