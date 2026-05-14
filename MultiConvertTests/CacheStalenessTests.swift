import Testing
import Foundation
@testable import MultiConvert

@Suite("Cache Staleness")
struct CacheStalenessTests {
    @Test func freshSnapshotNotStale() {
        let snap = RateSnapshot(ratesPerUSD: ["USD": 1.0], fetchedAt: Date())
        #expect(!snap.isStale)
    }

    @Test func snapshotJustUnder24hNotStale() {
        let fetchedAt = Date().addingTimeInterval(-(86_400 - 60))
        let snap = RateSnapshot(ratesPerUSD: ["USD": 1.0], fetchedAt: fetchedAt)
        #expect(!snap.isStale)
    }

    @Test func snapshotExactly24hIsStale() {
        let fetchedAt = Date().addingTimeInterval(-86_400)
        let snap = RateSnapshot(ratesPerUSD: ["USD": 1.0], fetchedAt: fetchedAt)
        #expect(snap.isStale)
    }

    @Test func snapshotOver24hIsStale() {
        let fetchedAt = Date().addingTimeInterval(-90_000)
        let snap = RateSnapshot(ratesPerUSD: ["USD": 1.0], fetchedAt: fetchedAt)
        #expect(snap.isStale)
    }

    @Test func oldSnapshotIsStale() {
        let weekAgo = Date().addingTimeInterval(-7 * 86_400)
        let snap = RateSnapshot(ratesPerUSD: ["USD": 1.0], fetchedAt: weekAgo)
        #expect(snap.isStale)
    }

    @Test func rateCacheRoundTrip() throws {
        let cache = RateCache(filename: "test_rates_\(UUID().uuidString).json")
        defer { cache.clear() }

        let snap = RateSnapshot(ratesPerUSD: ["USD": 1.0, "EUR": 0.92], fetchedAt: Date())
        try cache.save(snap)

        let loaded = cache.snapshot
        #expect(loaded != nil)
        #expect(loaded?.ratesPerUSD["EUR"] == 0.92)
    }

    @Test func rateCacheClear() throws {
        let cache = RateCache(filename: "test_clear_\(UUID().uuidString).json")
        let snap = RateSnapshot(ratesPerUSD: ["USD": 1.0], fetchedAt: Date())
        try cache.save(snap)

        cache.clear()
        #expect(cache.snapshot == nil)
    }

    @Test func rateCacheMissingFileReturnsNil() {
        let cache = RateCache(filename: "nonexistent_\(UUID().uuidString).json")
        #expect(cache.snapshot == nil)
    }
}
