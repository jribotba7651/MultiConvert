import Testing
import Foundation
@testable import MultiConvert

@Suite("Replace Currency (per-row picker)")
struct ReplaceCurrencyTests {

    // Build a fresh AppState with a controlled MRU list to avoid UserDefaults pollution.
    private func stateWith(_ currencies: [Currency], base: Currency) -> AppState {
        let s = AppState()
        s.recentCurrencies = currencies
        s.baseCurrency = base
        return s
    }

    @Test func replaceWithNewCurrencyUpdatesThatRow() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, eur, gbp], base: usd)

        s.replaceCurrency(at: 1, with: jpy) // EUR row -> JPY, JPY wasn't in the list

        #expect(s.recentCurrencies == [usd, jpy, gbp])
        #expect(s.baseCurrency == usd) // unaffected — didn't touch the base row
    }

    @Test func replaceWithCurrencyAlreadyInListSwaps() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, eur, gbp, jpy], base: usd)

        s.replaceCurrency(at: 1, with: jpy) // EUR row -> JPY, JPY already at index 3

        #expect(s.recentCurrencies == [usd, jpy, gbp, eur])
    }

    @Test func replacingBaseRowUpdatesBaseCurrency() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!
        let s = stateWith([usd, eur, gbp], base: usd)

        s.replaceCurrency(at: 0, with: gbp) // base row (USD) -> GBP

        #expect(s.recentCurrencies == [gbp, eur, usd])
        #expect(s.baseCurrency == gbp)
    }

    @Test func replacingBaseRowWithSwapAlsoUpdatesBase() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!
        let s = stateWith([usd, eur, gbp], base: usd)

        s.replaceCurrency(at: 0, with: gbp) // base row (USD) swaps with GBP at index 2

        #expect(s.recentCurrencies[0] == gbp)
        #expect(s.recentCurrencies[2] == usd)
        #expect(s.baseCurrency == gbp)
    }

    @Test func replaceWithSameCurrencyIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur], base: usd)

        s.replaceCurrency(at: 1, with: eur)

        #expect(s.recentCurrencies == [usd, eur])
        #expect(s.baseCurrency == usd)
    }

    @Test func replaceAtOutOfBoundsIndexIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur], base: usd)

        s.replaceCurrency(at: 5, with: Currency.find(code: "JPY")!)

        #expect(s.recentCurrencies == [usd, eur])
    }
}
