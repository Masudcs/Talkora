import Foundation

/// Simulates the two things a real network call would introduce that a direct in-memory
/// read would not: latency and occasional failure. Tuned per environment via `AppEnvironment`
/// (see `AppEnvironment.mockLatencyRange` / `mockErrorInjectionRate`) so Development stays fast
/// for iteration while Staging exercises loading/error UI realistically.
public struct MockNetworkSimulator: Sendable {
    private let environment: AppEnvironment

    public init(environment: AppEnvironment = .current) {
        self.environment = environment
    }

    /// Sleeps for a random duration within the environment's range; a zero upper bound skips the delay.
    public func simulateLatency() async throws {
        let range = environment.mockLatencyRange
        guard range.upperBound > 0 else { return }
        let seconds = Double.random(in: range)
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    /// Randomly fails GET requests only, so loading and error states get exercised without ever dropping a user's write.
    public func maybeThrowInjectedError(for endpoint: Endpoint) throws {
        guard endpoint.method == .get else { return } // never randomly fail user-initiated writes
        guard Double.random(in: 0...1) < environment.mockErrorInjectionRate else { return }
        throw APIError.network(underlying: "Simulated transient network failure for \(endpoint.path)")
    }
}
