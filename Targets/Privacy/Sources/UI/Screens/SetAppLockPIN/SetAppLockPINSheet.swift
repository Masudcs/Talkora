import SwiftUI
import Core
import CommonUI

/// Reuses the onboarding `PINSetupScreen`'s look, but for setting/changing a PIN from the
/// Privacy hub rather than as a one-time onboarding step.
struct SetAppLockPINSheet: View {
    /// Called after the PIN was saved, just before the sheet dismisses.
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SetAppLockPINViewModel

    init(onSaved: @escaping () -> Void, viewModel: SetAppLockPINViewModel = SetAppLockPINViewModel()) {
        self.onSaved = onSaved
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("Set a PIN to lock Talkora whenever it goes to the background.")
                    .font(Font.body)
                    .foregroundStyle(Color.secondary)

                SecureField("4-digit PIN", text: Bindable(viewModel).pin)
                    .keyboardType(.numberPad)
                    .font(Font.title2.weight(.semibold))
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: viewModel.pin) {
                        viewModel.pinChanged()
                    }

                SecureField("Confirm PIN", text: Bindable(viewModel).confirmPin)
                    .keyboardType(.numberPad)
                    .font(Font.title2.weight(.semibold))
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: viewModel.confirmPin) {
                        viewModel.confirmPinChanged()
                    }

                if viewModel.pinsMismatch {
                    Text("PINs don't match.")
                        .font(Font.caption)
                        .foregroundStyle(Color.red)
                }
                if let error = viewModel.error {
                    Text(error.userMessage)
                        .font(Font.caption)
                        .foregroundStyle(Color.red)
                }

                Spacer()

                if viewModel.isSaving {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    TalkoraButton("Save PIN") {
                        Task {
                            if await viewModel.save() {
                                onSaved()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                    .opacity(viewModel.canSubmit ? 1 : 0.5)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .navigationTitle("App Lock PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Empty") {
    SetAppLockPINSheet(onSaved: {}, viewModel: SetAppLockPINViewModel(previewScenario: .empty))
}

#Preview("Mismatch") {
    SetAppLockPINSheet(onSaved: {}, viewModel: SetAppLockPINViewModel(previewScenario: .invalid))
}

#Preview("Filled") {
    SetAppLockPINSheet(onSaved: {}, viewModel: SetAppLockPINViewModel(previewScenario: .filled))
}

#Preview("Saving") {
    SetAppLockPINSheet(onSaved: {}, viewModel: SetAppLockPINViewModel(previewScenario: .submitting))
}

#Preview("Error") {
    SetAppLockPINSheet(onSaved: {}, viewModel: SetAppLockPINViewModel(previewScenario: .failed))
}
#endif
