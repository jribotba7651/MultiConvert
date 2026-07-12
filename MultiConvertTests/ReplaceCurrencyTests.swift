import Testing
import Foundation
@testable import MultiConvert

@Suite("Replace Currency (per-row picker)")
struct ReplaceCurrencyTests {

    // The base is always recentCurrencies[0]; there is no separate base to set.
    private func stateWith(_ currencies: [Currency]) -> AppState {
        let s = AppState()
        s.recentCurrencies = currencies
        return s
    }

    @Test func replaceWithNewCurrencyUpdatesThatRow() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, eur, gbp])

        s.replaceCurrency(at: 1, with: jpy) // EUR row -> JPY, JPY wasn't in the list

        #expect(s.recentCurrencies == [usd, jpy, gbp])
        #expect(s.baseCurrency == usd) // unaffected — didn't touch the base row
    }

    @Test func replaceWithCurrencyAlreadyInListSwaps() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, eur, gbp, jpy])

        s.replaceCurrency(at: 1, with: jpy) // EUR row -> JPY, JPY already at index 3

        #expect(s.recentCurrencies == [usd, jpy, gbp, eur])
    }

    @Test func replacingBaseRowUpdatesBaseCurrency() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!
        let s = stateWith([usd, eur, gbp])

        s.replaceCurrency(at: 0, with: gbp) // base row (USD) -> GBP, GBP already at index 2

        #expect(s.recentCurrencies == [gbp, eur, usd])
        #expect(s.baseCurrency == gbp)
    }

    @Test func replacingBaseRowWithBrandNewCurrencyRebases() {
        let usd = Currency.usd, eur = Currency.eur
        let cad = Currency.find(code: "CAD")!
        let s = stateWith([usd, eur])

        s.replaceCurrency(at: 0, with: cad) // CAD not in the list

        #expect(s.recentCurrencies == [cad, eur])
        #expect(s.baseCurrency == cad)
    }

    @Test func replaceWithSameCurrencyIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur])

        s.replaceCurrency(at: 1, with: eur)

        #expect(s.recentCurrencies == [usd, eur])
        #expect(s.baseCurrency == usd)
    }

    @Test func replaceAtOutOfBoundsIndexIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur])

        s.replaceCurrency(at: 5, with: Currency.find(code: "JPY")!)

        #expect(s.recentCurrencies == [usd, eur])
    }
}
