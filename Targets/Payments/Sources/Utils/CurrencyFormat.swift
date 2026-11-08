import Foundation
import Core

/// Formats wallet amounts. Everything is USD; the wallet has no per-user currency.
enum CurrencyFormat {
    /// Shared because `NumberFormatter` is expensive to create.
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()

    static func string(_ amount: Double) -> String {
        formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}
