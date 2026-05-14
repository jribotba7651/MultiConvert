import Foundation

/// Orchestrates FiatProvider + CryptoProvider, merges into a single RateSnapshot,
/// falls back to the on-disk cache when the network is unavailable.
final class ConversionEngine {
    private let fiat: FiatProvider
    private let crypto: CryptoProvider
    private let cache: RateCache

    init(
        fiat: FiatProvider = FiatProvider(),
        crypto: CryptoProvider = CryptoProvider(),
        cache: RateCache = RateCache()
    ) {
        self.fiat = fiat
        self.crypto = crypto
        self.cache = cache
    }

    /// Fetches fresh rates from both APIs, merges them, caches the result.
    /// Throws if both fail and no cached snapshot is available.
    func fetchRates() async throws -> RateSnapshot {
        var merged: [String: Double] = [:]

        if let rates = try? await fiat.fetchRatesPerUSD() {
            merged.merge(rates) { _, new in new }
        }

        if let rates = try? await crypto.fetchRatesPerUSD() {
            merged.merge(rates) { _, new in new }
        }

        if !merged.isEmpty {
            let snapshot = RateSnapshot(ratesPerUSD: merged, fetchedAt: Date())
            try? cache.save(snapshot)
            return snapshot
        }

        if let cached = cache.snapshot {
            return cached
        }

        throw ProviderError.networkUnavailable
    }

    var cachedSnapshot: RateSnapshot? { cache.snapshot }

    func clearCache() { cache.clear() }
}
