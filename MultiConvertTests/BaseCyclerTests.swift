import Testing
import Foundation
@testable import MultiConvert

@Suite("Base Currency Cycler")
struct BaseCyclerTests {

    // Build a fresh AppState with a controlled MRU list to avoid UserDefaults pollution.
    private func stateWith(_ currencies: [Currency]) -> AppState {
        let s = AppState()
        s.recentCurrencies = currencies
        return s
    }

    @Test func cycleUpFromIndexZeroWrapsToLast() {
        let currencies = [Currency.eur, Currency.find(code: "GBP")!, Currency.find(code: "JPY")!]
        let s = stateWith(currencies)
        s.baseCurrency = currencies[0]          // EUR — index 0
        s.cycleBase(.up)
        #expect(s.baseCurrency == currencies[2]) // wraps to JPY (last)
    }

    @Test func cycleDownFromLastIndexWrapsToFirst() {
        let currencies = [Currency.eur, Currency.find(code: "GBP")!, Currency.find(code: "JPY")!]
        let s = stateWith(currencies)
        s.baseCurrency = currencies[2]          // JPY — last
        s.cycleBase(.down)
        #expect(s.baseCurrency == currencies[0]) // wraps to EUR (first)
    }

    @Test func cycleDownAdvancesForward() {
        let currencies = [Currency.eur, Currency.find(code: "GBP")!, Currency.find(code: "JPY")!]
        let s = stateWith(currencies)
        s.baseCurrency = currencies[0]          // EUR
        s.cycleBase(.down)
        #expect(s.baseCurrency == currencies[1]) // GBP
    }

    @Test func cycleUpAdvancesBackward() {
        let currencies = [Currency.eur, Currency.find(code: "GBP")!, Currency.find(code: "JPY")!]
        let s = stateWith(currencies)
        s.baseCurrency = currencies[2]          // JPY
        s.cycleBase(.up)
        #expect(s.baseCurrency == currencies[1]) // GBP
    }

    @Test func cycleDoesNothingOnEmptyList() {
        let s = AppState()
        s.recentCurrencies = []
        let before = s.baseCurrency
        s.cycleBase(.down)
        s.cycleBase(.up)
        #expect(s.baseCurrency == before)        // unchanged
    }

    @Test func cycleUpdatesBaseCurrencyTriggersConversionChange() {
        // Ensures baseCurrency actually changes (conversions re-derive from it)
        let currencies = [Currency.eur, Currency.find(code: "GBP")!, Currency.find(code: "MXN")!]
        let s = stateWith(currencies)
        s.baseCurrency = currencies[0]
        let before = s.baseCurrency
        s.cycleBase(.down)
        #expect(s.baseCurrency != before)
        #expect(s.baseCurrency == currencies[1])
    }

    @Test func cycleWhenBaseNotInListStartsFromEdge() {
        // If current base is not in MRU, down goes to index 0, up goes to last
        let currencies = [Currency.eur, Currency.find(code: "GBP")!]
        let s = stateWith(currencies)
        s.baseCurrency = Currency.find(code: "CAD")! // not in MRU
        s.cycleBase(.down)
        #expect(s.baseCurrency == currencies[0])     // first item
    }
}
