import Testing
import Foundation
@testable import MultiConvert

@Suite("MRU Cache")
struct MRUCacheTests {
    @Test func insertIntoEmpty() {
        var cache = MRUCache<String>(capacity: 10)
        cache.use("USD")
        #expect(cache.items == ["USD"])
    }

    @Test func mostRecentIsFirst() {
        var cache = MRUCache<String>(capacity: 10)
        cache.use("USD")
        cache.use("EUR")
        cache.use("JPY")
        #expect(cache.items.first == "JPY")
    }

    @Test func reuseMoveToFront() {
        var cache = MRUCache<String>(capacity: 10)
        cache.use("USD")
        cache.use("EUR")
        cache.use("JPY")
        cache.use("USD") // USD was at index 2, should move to front
        #expect(cache.items.first == "USD")
        #expect(cache.items.count == 3)
    }

    @Test func capacityEnforced() {
        var cache = MRUCache<Int>(capacity: 3)
        for i in 1...5 { cache.use(i) }
        #expect(cache.count == 3)
        #expect(cache.items == [5, 4, 3])
    }

    @Test func removeItem() {
        var cache = MRUCache<String>(capacity: 10)
        cache.use("USD")
        cache.use("EUR")
        cache.remove("USD")
        #expect(!cache.items.contains("USD"))
        #expect(cache.items == ["EUR"])
    }

    @Test func clearAll() {
        var cache = MRUCache<String>(capacity: 10)
        cache.use("A"); cache.use("B"); cache.use("C")
        cache.clear()
        #expect(cache.isEmpty)
    }

    @Test func noDuplicates() {
        var cache = MRUCache<String>(capacity: 10)
        cache.use("X")
        cache.use("X")
        cache.use("X")
        #expect(cache.count == 1)
    }

    @Test func orderPreserved() {
        var cache = MRUCache<String>(capacity: 5)
        ["A", "B", "C", "D", "E"].forEach { cache.use($0) }
        #expect(cache.items == ["E", "D", "C", "B", "A"])
    }

    @Test func dropOffOldest() {
        var cache = MRUCache<String>(capacity: 3)
        cache.use("A"); cache.use("B"); cache.use("C"); cache.use("D")
        #expect(!cache.items.contains("A"))
    }

    @Test func capacityOfOne() {
        var cache = MRUCache<String>(capacity: 1)
        cache.use("A")
        cache.use("B")
        #expect(cache.items == ["B"])
    }
}
