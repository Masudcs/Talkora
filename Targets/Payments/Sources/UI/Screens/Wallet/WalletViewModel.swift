import Foundation
import Observation
import Core
import Mock

/// Drives the wallet screen: balance, KYC status, transaction history and the top-up/KYC sheets. Sending money requires `isVerified`; the mock backend rejects transfers from unverified wallets.
@MainActor
@Observable
final class WalletViewModel {
    /// Makes `load()` a no-op so preview data is not overwritten by the mock backend. Not observed because the UI never reads it.
    @ObservationIgnored private var isPreview = false
    private(set) var wallet: Wallet?
    private(set) var transactionsState: LoadableState<[PaymentTransaction]> = .idle
    /// Used to decide whether a transaction is incoming or outgoing; empty until `load()` has fetched the user.
    private(set) var currentUserId: String = ""
    /// Cache of other participants by id, so reloads only fetch users not seen before.
    private(set) var counterparts: [String: User] = [:]
    var isKYCPresented = false
    var isTopUpPresented = false
    /// Failure from `submitKYC` or `topUp`. Load errors go to `transactionsState` instead.
    private(set) var actionError: AppError?

    private let repository: IPaymentRepository
    private let userRepository: IUserRepository

    init(repository: IPaymentRepository = PaymentRepository(), userRepository: IUserRepository = UserRepository()) {
        self.repository = repository
        self.userRepository = userRepository
    }

    var transactions: [PaymentTransaction] {
        transactionsState.value ?? []
    }

    /// Whether KYC is complete; the screen hides the "Verify Identity" row once true.
    var isVerified: Bool {
        wallet?.kycStatus == .verified
    }

    /// Name of the other party, or "Someone" if the user lookup failed or has not loaded.
    func counterpartName(for transaction: PaymentTransaction) -> String {
        let otherId = transaction.fromUserId == currentUserId ? transaction.toUserId : transaction.fromUserId
        return counterparts[otherId]?.displayName ?? "Someone"
    }

    /// Loads user, wallet, then history, then missing counterparts, in that order, because the direction of each transaction depends on `currentUserId`. A failed wallet fetch is swallowed (the balance shows 0 or stays stale); only the history fetch reports an error.
    func load() async {
        guard !isPreview else { return }
        currentUserId = (try? await userRepository.currentUser().id) ?? currentUserId
        wallet = try? await repository.wallet()
        transactionsState = .loading
        do {
            let items = try await repository.transactions()
            transactionsState = items.isEmpty ? .empty : .loaded(items)
            var fetched = counterparts
            let otherIds = Set(items.map { $0.fromUserId == currentUserId ? $0.toUserId : $0.fromUserId })
            for id in otherIds where fetched[id] == nil {
                if let user = try? await userRepository.user(id: id) {
                    fetched[id] = user
                }
            }
            counterparts = fetched
        } catch {
            transactionsState = .failed(error.asAppError)
        }
    }

    /// Submits the simulated KYC, then reloads so `isVerified` updates.
    func submitKYC(fullName: String, country: String) async {
        do {
            _ = try await repository.submitKYC(fullName: fullName, country: country)
            await load()
        } catch {
            actionError = error.asAppError
        }
    }

    /// Credits the wallet, then reloads the balance and history.
    func topUp(amount: Double) async {
        do {
            _ = try await repository.topUp(amount: amount)
            await load()
        } catch {
            actionError = error.asAppError
        }
    }
}

#if DEBUG
extension WalletViewModel {
    convenience init(previewScenario scenario: PreviewScenario) {
        self.init()
        isPreview = true
        wallet = PreviewData.wallet
        currentUserId = PreviewData.currentUser.id
        counterparts = Dictionary(uniqueKeysWithValues: PreviewData.users.map { ($0.id, $0) })
        transactionsState = scenario.state(PreviewData.transactions)
    }
}
#endif
