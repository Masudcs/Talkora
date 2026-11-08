import SwiftUI
import Core
import CommonUI

/// Shown instead of `RootView` whenever `AppLockManager.isLocked` is true — on cold launch
/// with app lock enabled, or after returning from the background.
public struct AppLockScreen: View {
    @State private var viewModel: AppLockViewModel

    /// Internal initializer for tests and previews to inject a view model.
    init(viewModel: AppLockViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    /// Public entry point for the app shell, which can't see the internal view model.
    public init() {
        self.init(viewModel: AppLockViewModel())
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
            Text("Talkora Locked")
                .font(Font.title2.weight(.semibold))
            Text("Enter your PIN to continue.")
                .font(Font.body)
                .foregroundStyle(Color.secondary)

            SecureField("PIN", text: Bindable(viewModel).pin)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(Font.title2.weight(.semibold))
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: 200)
                .onChange(of: viewModel.pin) {
                    viewModel.pinChanged()
                }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Font.caption)
                    .foregroundStyle(Color.red)
            }

            if viewModel.isVerifying {
                ProgressView()
            } else {
                TalkoraButton("Unlock") {
                    Task { await viewModel.unlock() }
                }
                .disabled(!viewModel.canSubmit)
                .opacity(viewModel.canSubmit ? 1 : 0.5)
                .frame(maxWidth: 200)
            }
            Spacer()
        }
        .padding(24)
        .background(Color(.systemBackground))
    }
}

#if DEBUG
#Preview("Empty") {
    AppLockScreen(viewModel: AppLockViewModel(previewScenario: .empty))
}

#Preview("Partial PIN") {
    AppLockScreen(viewModel: AppLockViewModel(previewScenario: .invalid))
}

#Preview("Ready") {
    AppLockScreen(viewModel: AppLockViewModel(previewScenario: .filled))
}

#Preview("Verifying") {
    AppLockScreen(viewModel: AppLockViewModel(previewScenario: .submitting))
}

#Preview("Wrong PIN") {
    AppLockScreen(viewModel: AppLockViewModel(previewScenario: .failed))
}
#endif
