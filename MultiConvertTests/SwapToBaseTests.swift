import Testing
import Foundation
@testable import MultiConvert

@Suite("Swap To Base (header picker)")
struct SwapToBaseTests {

    // Build a fresh AppState with a controlled MRU list to avoid UserDefaults pollution.
    private func stateWith(_ currencies: [Currency], base: Currency) -> AppState {
        let s = AppState()
        s.recentCurrencies = currencies
        s.baseCurrency = base
        return s
    }

    @Test func swapToBaseUpdatesBaseCurrency() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!
        let s = stateWith([usd, eur, gbp], base: usd)

        s.swapToBase(eur)

        #expect(s.baseCurrency == eur)
        #expect(s.recentCurrencies[0] == eur) // index 0 is sacred
    }

    @Test func swapToBaseWithCurrencyAlreadyInListSwapsInsteadOfRemoving() {
        // Index 0 is sacred and always holds a row now — the base is never
        // pulled out of the list, it swaps places with whatever was there.
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!
        let s = stateWith([usd, eur, gbp], base: usd)

        s.swapToBase(eur)

        #expect(s.recentCurrencies == [eur, usd, gbp]) // pure swap — GBP untouched
        #expect(s.recentCurrencies.filter { $0 == eur }.count == 1) // no duplicate
    }

    @Test func swapToBaseWithCurrencyNotInListInsertsItAtIndexZero() {
        let usd = Currency.usd
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let cad = Currency.find(code: "CAD")!
        let s = stateWith([usd, gbp, jpy], base: usd)

        s.swapToBase(cad) // CAD wasn't a row

        #expect(s.baseCurrency == cad)
        #expect(s.recentCurrencies[0] == cad)
        #expect(s.recentCurrencies.contains(usd)) // old base preserved as a row
        #expect(s.recentCurrencies.count == 4) // nothing lost, list grew by one
    }

    @Test func swapToBaseWithCurrencyNotInListPutsOutgoingBaseRightAfterIt() {
        let usd = Currency.usd
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let cad = Currency.find(code: "CAD")!
        let s = stateWith([usd, gbp, jpy], base: usd)

        s.swapToBase(cad)

        #expect(s.recentCurrencies == [cad, usd, gbp, jpy])
    }

    @Test func swapToBaseWithSameCurrencyIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur], base: usd)

        s.swapToBase(usd)

        #expect(s.baseCurrency == usd)
        #expect(s.recentCurrencies == [usd, eur])
    }

    @Test func replacingANonBaseRowNeverChangesTheBase() {
        // Guards the header/row separation: only swapToBase (or moving a row
        // to index 0 via moveCurrency) may promote a new base.
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, eur, gbp], base: usd)

        s.replaceCurrency(at: 1, with: jpy) // change row 1 (EUR -> JPY), not the base row

        #expect(s.baseCurrency == usd)
        #expect(s.recentCurrencies[0] == usd)
    }
}
