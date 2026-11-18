import Foundation

/// A rate API the engine talks to.
enum RateSource: String, CaseIterable, Hashable {
    case fiat
    case crypto

    var displayName: String {
        switch self {
        case .fiat:   "Fiat rates (ExchangeRate-API)"
        case .crypto: "Crypto prices (CoinGecko)"
        }
    }
}

/// Result of a refresh: the snapshot to show plus any sources that failed
/// this time (their rates come from the cache).
struct RateFetchResult {
    let snapshot: RateSnapshot
    let failedSources: [RateSource]
}

/// Orchestrates FiatProvider + CryptoProvider, merges into a single RateSnapshot,
/// and falls back to the on-disk cache per source when an API fails.
final class ConversionEngine {
    private let fiat: any RateProvider
    private let crypto: any RateProvider
    private let cache: RateCache

    init(
        fiat: any RateProvider = FiatProvider(),
        crypto: any RateProvider = CryptoProvider(),
        cache: RateCache = RateCache()
    ) {
        self.fiat = fiat
        self.crypto = crypto
        self.cache = cache
    }

    /// Fetches both APIs in parallel. A source that fails keeps its rates
    /// from the cached snapshot (and its old timestamp), so e.g. a CoinGecko
    /// rate limit never wipes crypto rates. Throws only if both fail and
    /// nothing is cached.
    func fetchRates(now: Date = Date()) async throws -> RateFetchResult {
        async let fiatResult = Self.fetch(fiat)
        async let cryptoResult = Self.fetch(crypto)
        let (fiatRates, cryptoRates) = await (fiatResult, cryptoResult)

        let cached = cache.snapshot
        let cryptoCodes = crypto.supportedCodes
        var failed: [RateSource] = []
        var merged: [String: Double] = [:]

        let fiatAt: Date?
        if let fiatRates {
            merged.merge(fiatRates) { _, new in new }
            fiatAt = now
        } else {
            failed.append(.fiat)
            if let cached {
                merged.merge(cached.ratesPerUSD.filter { !cryptoCodes.contains($0.key) }) { _, new in new }
            }
            fiatAt = cached.map { $0.fiatFetchedAt ?? $0.fetchedAt }
        }

        let cryptoAt: Date?
        if let cryptoRates {
            merged.merge(cryptoRates) { _, new in new }
            cryptoAt = now
        } else {
            failed.append(.crypto)
            if let cached {
                merged.merge(cached.ratesPerUSD.filter { cryptoCodes.contains($0.key) }) { _, new in new }
            }
            cryptoAt = cached.map { $0.cryptoFetchedAt ?? $0.fetchedAt }
        }

        if failed.count == RateSource.allCases.count {
            guard let cached else { throw ProviderError.networkUnavailable }
            return RateFetchResult(snapshot: cached, failedSources: failed)
        }

        // Everything is quoted per USD, so USD must always resolve.
        merged["USD"] = merged["USD"] ?? 1.0

        let oldest = [fiatAt, cryptoAt].compactMap { $0 }.min() ?? now
        let snapshot = RateSnapshot(
            ratesPerUSD: merged,
            fetchedAt: oldest,
            fiatFetchedAt: fiatAt,
            cryptoFetchedAt: cryptoAt
        )
        try? cache.save(snapshot)
        return RateFetchResult(snapshot: snapshot, failedSources: failed)
    }

    var cachedSnapshot: RateSnapshot? { cache.snapshot }

    func clearCache() { cache.clear() }

    private static func fetch(_ provider: any RateProvider) async -> [String: Double]? {
        do {
            let rates = try await provider.fetchRatesPerUSD()
            return rates.isEmpty ? nil : rates
        } catch {
            #if DEBUG
            print("[ConversionEngine] \(type(of: provider)) failed: \(error.localizedDescription)")
            #endif
            return nil
        }
    }
}
