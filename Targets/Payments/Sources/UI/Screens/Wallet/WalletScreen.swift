import SwiftUI
import Core

/// Wallet tab destination: balance, top-up, identity check (shown only until verified) and transaction history. Pushed, so it has no `NavigationStack` of its own.
struct WalletScreen: View {
    @State private var viewModel: WalletViewModel

    init(viewModel: WalletViewModel = WalletViewModel()) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Balance")
                        .font(Font.caption)
                        .foregroundStyle(Color.secondary)
                    Text(CurrencyFormat.string(viewModel.wallet?.balance ?? 0))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)

                Button("Top Up") { viewModel.isTopUpPresented = true }
            }

            if !viewModel.isVerified {
                Section {
                    Button("Verify Identity") { viewModel.isKYCPresented = true }
                } footer: {
                    Text("Sending money requires a quick identity check first.")
                }
            }

            if let error = viewModel.actionError {
                Section {
                    Text(error.userMessage).foregroundStyle(Color.red)
                }
            }

            Section {
                switch viewModel.transactionsState {
                case .idle, .loading:
                    ProgressView()
                case .empty:
                    Text("No transactions yet.")
                        .foregroundStyle(Color.secondary)
                case .failed(let error):
                    Text(error.userMessage).foregroundStyle(Color.red)
                case .loaded(let transactions):
                    ForEach(transactions) { transaction in
                        TransactionRow(
                            transaction: transaction,
                            currentUserId: viewModel.currentUserId,
                            counterpartName: viewModel.counterpartName(for: transaction)
                        )
                    }
                }
            } header: {
                Text("History")
            }
        }
        .navigationTitle("Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isKYCPresented) {
            KYCSheet { fullName, country in
                await viewModel.submitKYC(fullName: fullName, country: country)
            }
        }
        .sheet(isPresented: $viewModel.isTopUpPresented) {
            TopUpSheet { amount in
                await viewModel.topUp(amount: amount)
            }
        }
        .task { await viewModel.load() }
    }
}

/// One history row. Green/red and the arrow reflect direction relative to the current user.
private struct TransactionRow: View {
    let transaction: PaymentTransaction
    let currentUserId: String
    let counterpartName: String

    /// Only a `.send` the user made counts as outgoing; a request the user made is not money leaving.
    private var isOutgoing: Bool {
        transaction.fromUserId == currentUserId && transaction.kind == .send
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: transaction.kind == .send ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(isOutgoing ? Color.red : Color.green)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                if transaction.status == .pendingAcceptance {
                    Text("Pending").font(.caption2).foregroundStyle(Color.secondary)
                } else if transaction.status == .declined {
                    Text("Declined").font(.caption2).foregroundStyle(Color.red)
                }
            }
            Spacer()
            Text(CurrencyFormat.string(transaction.amount))
                .foregroundStyle(isOutgoing ? Color.primary : Color.green)
        }
    }

    private var label: String {
        switch transaction.kind {
        case .send:
            return transaction.fromUserId == currentUserId ? "To \(counterpartName)" : "From \(counterpartName)"
        case .request:
            return transaction.fromUserId == currentUserId ? "Requested from \(counterpartName)" : "Requested by \(counterpartName)"
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack { WalletScreen(viewModel: WalletViewModel(previewScenario: .loaded)) }
}

#Preview("Loading") {
    NavigationStack { WalletScreen(viewModel: WalletViewModel(previewScenario: .loading)) }
}

#Preview("Empty") {
    NavigationStack { WalletScreen(viewModel: WalletViewModel(previewScenario: .empty)) }
}

#Preview("Error") {
    NavigationStack { WalletScreen(viewModel: WalletViewModel(previewScenario: .failed)) }
}
#endif
