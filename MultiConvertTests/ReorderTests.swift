import Testing
import Foundation
@testable import MultiConvert

@Suite("Move Currency (drag reorder & re-basing)")
struct ReorderTests {

    // Build a fresh AppState with a controlled MRU list to avoid UserDefaults pollution.
    private func stateWith(_ currencies: [Currency], base: Currency) -> AppState {
        let s = AppState()
        s.recentCurrencies = currencies
        s.baseCurrency = base
        return s
    }

    @Test func moveToIndexZeroSwapsWithBase() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, gbp, jpy, eur], base: usd)

        s.moveCurrency(from: 3, to: 0) // drag EUR (index 3) to the top

        #expect(s.recentCurrencies == [eur, gbp, jpy, usd])
        #expect(s.baseCurrency == eur)
    }

    @Test func moveToIndexZeroDoesNotShiftOtherItems() {
        // "Swap, not shift": rows between the dragged item and the base must
        // keep their original position.
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, gbp, jpy, eur], base: usd)

        s.moveCurrency(from: 3, to: 0)

        #expect(s.recentCurrencies[1] == gbp)
        #expect(s.recentCurrencies[2] == jpy)
    }

    @Test func movingBaseOutOfIndexZeroPromotesWhoeverSlidesUp() {
        // Index 0 is sacred: dragging the base elsewhere must hand the base
        // off to whichever row naturally ends up at index 0 afterwards. This
        // is the exact regression this fix addresses — previously the base
        // stayed pinned to the dragged currency instead of following index 0.
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, eur, gbp, jpy], base: usd)

        s.moveCurrency(from: 0, to: 3) // drag the base row all the way to the end

        #expect(s.recentCurrencies == [eur, gbp, jpy, usd])
        #expect(s.baseCurrency == eur) // EUR slid up to index 0 — it's the new base
    }

    @Test func movingBaseToAMiddlePositionAlsoPromotesTheNewIndexZero() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, eur, gbp, jpy], base: usd)

        s.moveCurrency(from: 0, to: 2) // drag the base row to index 2, not the end

        #expect(s.recentCurrencies == [eur, gbp, usd, jpy])
        #expect(s.baseCurrency == eur)
    }

    @Test func moveInMiddleShiftsWithoutChangingBase() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, eur, gbp, jpy], base: usd)

        s.moveCurrency(from: 1, to: 3) // move EUR down to the last slot

        #expect(s.recentCurrencies == [usd, gbp, jpy, eur])
        #expect(s.baseCurrency == usd) // unchanged — this isn't a rebase
    }

    @Test func moveUpwardShiftsIntermediateItemsDown() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!, jpy = Currency.find(code: "JPY")!
        let s = stateWith([usd, gbp, jpy, eur], base: usd)

        s.moveCurrency(from: 3, to: 1) // move EUR up to index 1, not the top

        #expect(s.recentCurrencies == [usd, eur, gbp, jpy])
        #expect(s.baseCurrency == usd)
    }

    @Test func moveToSameIndexIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur], base: usd)

        s.moveCurrency(from: 1, to: 1)

        #expect(s.recentCurrencies == [usd, eur])
    }

    @Test func moveWithOutOfBoundsSourceIndexIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur], base: usd)

        s.moveCurrency(from: 5, to: 0)

        #expect(s.recentCurrencies == [usd, eur])
        #expect(s.baseCurrency == usd)
    }

    @Test func moveWithOutOfBoundsTargetIndexIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur], base: usd)

        s.moveCurrency(from: 0, to: 5)

        #expect(s.recentCurrencies == [usd, eur])
        #expect(s.baseCurrency == usd)
    }

    @Test func draggingBaseItselfToTopIsNoOp() {
        let usd = Currency.usd, eur = Currency.eur
        let s = stateWith([usd, eur], base: usd)

        s.moveCurrency(from: 0, to: 0)

        #expect(s.recentCurrencies == [usd, eur])
        #expect(s.baseCurrency == usd)
    }
}
