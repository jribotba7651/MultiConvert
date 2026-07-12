import Testing
import Foundation
@testable import MultiConvert

@Suite("Move Currency (drag reorder — uniform shift)")
struct ReorderTests {

    // The base is always recentCurrencies[0]; there is no separate base to set.
    private func stateWith(_ currencies: [Currency]) -> AppState {
        let s = AppState()
        s.recentCurrencies = currencies
        return s
    }

    @Test func moveToIndexZeroShiftsAndRebases() {
        // Uniform shift: remove + insert, NO swap special-case. Dragging the
        // last row to the top slides everyone else down by one.
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, gbp, jpy, eur])

        s.moveCurrency(from: 3, to: 0) // drag EUR (index 3) to the top

        #expect(s.recentCurrencies == [eur, usd, gbp, jpy])
        #expect(s.baseCurrency == eur)
    }

    @Test func movingBaseDownShiftsWhoeverIsBelowUp() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, eur, gbp, jpy])

        s.moveCurrency(from: 0, to: 3) // drag the base row to the end

        #expect(s.recentCurrencies == [eur, gbp, jpy, usd])
        #expect(s.baseCurrency == eur) // EUR slid up to index 0 — new base
    }

    @Test func movingBaseToAMiddlePositionRebasesToNewIndexZero() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, eur, gbp, jpy])

        s.moveCurrency(from: 0, to: 2) // drag the base row to index 2

        #expect(s.recentCurrencies == [eur, gbp, usd, jpy])
        #expect(s.baseCurrency == eur)
    }

    @Test func moveInMiddleShiftsWithoutChangingBase() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, eur, gbp, jpy])

        s.moveCurrency(from: 1, to: 3) // move EUR down to the last slot

        #expect(s.recentCurrencies == [usd, gbp, jpy, eur])
        #expect(s.baseCurrency == usd) // index 0 untouched — no rebase
    }

    @Test func moveUpwardShiftsIntermediateItemsDown() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, gbp, jpy, eur])

        s.moveCurrency(from: 3, to: 1) // move EUR up to index 1, not the top

        #expect(s.recentCurrencies == [usd, eur, gbp, jpy])
        #expect(s.baseCurrency == usd)
    }

    @Test func moveToSameIndexIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur])

        s.moveCurrency(from: 1, to: 1)

        #expect(s.recentCurrencies == [usd, eur])
    }

    @Test func moveWithOutOfBoundsSourceIndexIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur])

        s.moveCurrency(from: 5, to: 0)

        #expect(s.recentCurrencies == [usd, eur])
        #expect(s.baseCurrency == usd)
    }

    @Test func moveWithOutOfBoundsTargetIndexIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur])

        s.moveCurrency(from: 0, to: 5)

        #expect(s.recentCurrencies == [usd, eur])
        #expect(s.baseCurrency == usd)
    }

    @Test func draggingBaseItselfToTopIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur])

        s.moveCurrency(from: 0, to: 0)

        #expect(s.recentCurrencies == [usd, eur])
        #expect(s.baseCurrency == usd)
    }
}
