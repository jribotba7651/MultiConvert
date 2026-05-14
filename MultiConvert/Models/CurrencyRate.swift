import Foundation

/// All rates are stored as "units per USD":
/// ratesPerUSD["EUR"] = 0.92 means 1 USD = 0.92 EUR
/// ratesPerUSD["BTC"] ≈ 0.0000154 means 1 USD = 0.0000154 BTC
///
/// Conversion formula: result = amount × ratesPerUSD[to] / ratesPerUSD[from]
struct RateSnapshot: Codable {
    let ratesPerUSD: [String: Double]
    let fetchedAt: Date

    var isStale: Bool {
        Date().timeIntervalSince(fetchedAt) > 86_400
    }

    func convert(amount: Double, from: String, to: String) -> Double? {
        guard let fromRate = ratesPerUSD[from],
              let toRate = ratesPerUSD[to],
              fromRate > 0 else { return nil }
        return amount * toRate / fromRate
    }
}
