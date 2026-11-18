import Foundation

/// All rates are stored as "units per USD":
/// ratesPerUSD["EUR"] = 0.92 means 1 USD = 0.92 EUR
/// ratesPerUSD["BTC"] ≈ 0.0000154 means 1 USD = 0.0000154 BTC
///
/// Conversion formula: result = amount × ratesPerUSD[to] / ratesPerUSD[from]
struct RateSnapshot: Codable {
    let ratesPerUSD: [String: Double]
    /// When the oldest part of this snapshot was fetched. Drives staleness.
    let fetchedAt: Date
    /// Per-source fetch times. Optional so snapshots cached by older builds
    /// (which only had `fetchedAt`) still decode.
    var fiatFetchedAt: Date?
    var cryptoFetchedAt: Date?

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
