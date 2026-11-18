import Testing
import Foundation
@testable import MultiConvert

@Suite("Foreground Refresh")
struct ForegroundRefreshTests {
    private func makeState(fetchedAgo: TimeInterval?) -> AppState {
        let defaults = UserDefaults(suiteName: "fg_\(UUID().uuidString)")!
        let cache = RateCache(filename: "fg_\(UUID().uuidString).json",
                              directory: FileManager.default.temporaryDirectory)
        let state = AppState(defaults: defaults, engine: ConversionEngine(cache: cache))
        state.snapshot = fetchedAgo.map {
            RateSnapshot(ratesPerUSD: ["USD": 1], fetchedAt: Date().addingTimeInterval(-$0))
        }
        return state
    }

    @Test func noRatesNeedsRefresh() {
        #expect(makeState(fetchedAgo: nil).needsForegroundRefresh())
    }

    @Test func freshRatesDoNotRefresh() {
        #expect(!makeState(fetchedAgo: 14 * 60).needsForegroundRefresh())
    }

    @Test func ratesOlderThan15MinutesRefresh() {
        #expect(makeState(fetchedAgo: 16 * 60).needsForegroundRefresh())
    }

    @Test func loadingSuppressesRefresh() {
        let state = makeState(fetchedAgo: 60 * 60)
        state.isLoading = true
        #expect(!state.needsForegroundRefresh())
    }
}
