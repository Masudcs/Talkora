import SwiftUI
import Core

/// Improve: storage breakdown and export live on one screen, and the export file is
/// prepared proactively so sharing it is genuinely a single tap.
struct DataUsageScreen: View {
    @State private var viewModel: DataUsageViewModel

    init(viewModel: DataUsageViewModel = DataUsageViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                switch viewModel.statsState {
                case .idle, .loading:
                    ProgressView()
                case .empty:
                    Text("No media sent or received yet.")
                        .foregroundStyle(Color.secondary)
                case .failed(let error):
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.userMessage)
                            .foregroundStyle(Color.red)
                        if error.isRetryable {
                            Button("Try Again") { Task { await viewModel.load() } }
                        }
                    }
                case .loaded(let breakdown):
                    ForEach(breakdown) { item in
                        HStack {
                            Text(item.label)
                            Spacer()
                            Text(formattedSize(item.bytes))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    HStack {
                        Text("Total").bold()
                        Spacer()
                        Text(formattedSize(viewModel.totalBytes)).bold()
                    }
                }
            } header: {
                Text("Storage Usage")
            }

            Section {
                if let url = viewModel.exportFileURL {
                    ShareLink(item: url) {
                        Label("Export My Data", systemImage: "square.and.arrow.up")
                    }
                } else {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Preparing export…")
                            .foregroundStyle(Color.secondary)
                    }
                }
            } footer: {
                Text("A single JSON file with your profile and message history, ready to share or save.")
            }
        }
        .navigationTitle("Data & Storage")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    // Byte count in human units (KB, MB...) in file-size style.
    private func formattedSize(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack { DataUsageScreen(viewModel: DataUsageViewModel(previewScenario: .loaded)) }
}

#Preview("Loading") {
    NavigationStack { DataUsageScreen(viewModel: DataUsageViewModel(previewScenario: .loading)) }
}

#Preview("Empty") {
    NavigationStack { DataUsageScreen(viewModel: DataUsageViewModel(previewScenario: .empty)) }
}

#Preview("Error") {
    NavigationStack { DataUsageScreen(viewModel: DataUsageViewModel(previewScenario: .failed)) }
}
#endif
