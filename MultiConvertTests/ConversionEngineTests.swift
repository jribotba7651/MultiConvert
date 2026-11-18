import Testing
import Foundation
@testable import MultiConvert

private struct StubProvider: RateProvider {
    let rates: [String: Double]?
    let supportedCodes: Set<String>

    func fetchRatesPerUSD() async throws -> [String: Double] {
        guard let rates else { throw ProviderError.badResponse(429) }
        return rates
    }
}

@Suite("Conversion Engine")
struct ConversionEngineTests {
    private let cryptoCodes: Set<String> = ["BTC", "ETH"]

    private func makeCache() -> RateCache {
        RateCache(filename: "engine_\(UUID().uuidString).json",
                  directory: FileManager.default.temporaryDirectory)
    }

    private func engine(fiat: [String: Double]?, crypto: [String: Double]?, cache: RateCache) -> ConversionEngine {
        ConversionEngine(
            fiat: StubProvider(rates: fiat, supportedCodes: ["USD", "EUR"]),
            crypto: StubProvider(rates: crypto, supportedCodes: cryptoCodes),
            cache: cache
        )
    }

    @Test func bothSucceedMergesAndCaches() async throws {
        let cache = makeCache(); defer { cache.clear() }
        let now = Date()
        let result = try await engine(fiat: ["USD": 1, "EUR": 0.9], crypto: ["BTC": 0.00001], cache: cache)
            .fetchRates(now: now)

        #expect(result.failedSources.isEmpty)
        #expect(result.snapshot.ratesPerUSD["EUR"] == 0.9)
        #expect(result.snapshot.ratesPerUSD["BTC"] == 0.00001)
        #expect(result.snapshot.fiatFetchedAt == now)
        #expect(result.snapshot.cryptoFetchedAt == now)
        #expect(cache.snapshot?.ratesPerUSD["BTC"] == 0.00001)
    }

    @Test func cryptoFailureKeepsCachedCryptoRates() async throws {
        let cache = makeCache(); defer { cache.clear() }
        let old = Date().addingTimeInterval(-3_600)
        try cache.save(RateSnapshot(ratesPerUSD: ["USD": 1, "EUR": 0.8, "BTC": 0.00002], fetchedAt: old))

        let now = Date()
        let result = try await engine(fiat: ["USD": 1, "EUR": 0.9], crypto: nil, cache: cache)
            .fetchRates(now: now)

        #expect(result.failedSources == [.crypto])
        #expect(result.snapshot.ratesPerUSD["EUR"] == 0.9)        // fresh fiat
        #expect(result.snapshot.ratesPerUSD["BTC"] == 0.00002)    // cached crypto kept
        #expect(result.snapshot.cryptoFetchedAt == old)
        #expect(result.snapshot.fiatFetchedAt == now)
        #expect(result.snapshot.fetchedAt == old)                 // staleness follows oldest part
        #expect(cache.snapshot?.ratesPerUSD["BTC"] == 0.00002)    // cache not wiped
    }

    @Test func fiatFailureKeepsCachedFiatAndUSDResolves() async throws {
        let cache = makeCache(); defer { cache.clear() }
        let result = try await engine(fiat: nil, crypto: ["BTC": 0.00001], cache: cache)
            .fetchRates()

        #expect(result.failedSources == [.fiat])
        #expect(result.snapshot.ratesPerUSD["USD"] == 1)
        let usd = try #require(result.snapshot.convert(amount: 1, from: "BTC", to: "USD"))
        #expect(abs(usd - 100_000) < 0.001)
    }

    @Test func bothFailReturnsCache() async throws {
        let cache = makeCache(); defer { cache.clear() }
        try cache.save(RateSnapshot(ratesPerUSD: ["USD": 1, "EUR": 0.8], fetchedAt: Date()))

        let result = try await engine(fiat: nil, crypto: nil, cache: cache).fetchRates()
        #expect(Set(result.failedSources) == [.fiat, .crypto])
        #expect(result.snapshot.ratesPerUSD["EUR"] == 0.8)
    }

    @Test func bothFailWithoutCacheThrows() async {
        let cache = makeCache(); defer { cache.clear() }
        await #expect(throws: ProviderError.self) {
            _ = try await engine(fiat: nil, crypto: nil, cache: cache).fetchRates()
        }
    }

    @Test func legacySnapshotWithoutSourceDatesDecodes() throws {
        let json = #"{"ratesPerUSD":{"USD":1},"fetchedAt":700000000}"#.data(using: .utf8)!
        let snap = try JSONDecoder().decode(RateSnapshot.self, from: json)
        #expect(snap.fiatFetchedAt == nil)
        #expect(snap.cryptoFetchedAt == nil)
    }
}
