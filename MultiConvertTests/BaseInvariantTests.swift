import Testing
import Foundation
@testable import MultiConvert

/// Guards the core invariant of the reorder/base refactor: `recentCurrencies[0]`
/// IS the base currency, always — no entry point may leave a non-base at the top
/// slot, drop below/above the 10-item cap, or lose the base across a relaunch.
@Suite("Base = index 0 invariant")
struct BaseInvariantTests {

    private func stateWith(_ currencies: [Currency]) -> AppState {
        let s = AppState()
        s.recentCurrencies = currencies
        return s
    }

    // MARK: - Relaunch

    @Test func relaunchLoadsBaseFromPersistedIndexZero() {
        // Simulates the exact finding-1 crash path: base was changed, app
        // relaunches. The base must follow index 0, not reset to USD.
        //
        // An isolated UserDefaults suite keeps this deterministic — the shared
        // standard domain is written concurrently by every other test that
        // constructs an AppState, which would otherwise race this read.
        let suiteName = "BaseInvariantTests.relaunch"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let codes = ["EUR", "USD", "GBP"]
        defaults.set(try! JSONEncoder().encode(codes), forKey: "recentCurrencies_v2")

        let s = AppState(defaults: defaults) // "relaunch": reads the persisted list

        #expect(s.recentCurrencies.first == Currency.eur)
        #expect(s.baseCurrency == Currency.eur)
    }

    // MARK: - selectCurrency ('+')

    @Test func selectCurrencyNeverDisplacesTheBase() {
        let s = stateWith([Currency.usd, Currency.eur])
        let jpy = Currency.find(code: "JPY")!

        s.selectCurrency(jpy)

        #expect(s.recentCurrencies[0] == Currency.usd) // base slot untouched
        #expect(s.baseCurrency == Currency.usd)
        #expect(s.recentCurrencies[1] == jpy) // lands just below the base
    }

    // MARK: - replaceCurrency

    @Test func replacingNonBaseRowWithTheBaseSwapsAndKeepsABaseAtIndexZero() {
        let usd = Currency.usd, eur = Currency.eur, gbp = Currency.find(code: "GBP")!
        let s = stateWith([usd, eur, gbp])

        // On the GBP row (index 2), pick USD — the current base at index 0.
        s.replaceCurrency(at: 2, with: usd)

        #expect(s.recentCurrencies == [gbp, eur, usd]) // full position swap
        #expect(s.baseCurrency == gbp) // index 0 still holds a base, never empty
    }

    @Test func replacingTheIndexZeroRowChangesTheBase() {
        let usd = Currency.usd, eur = Currency.eur
        let gbp = Currency.find(code: "GBP")!
        let s = stateWith([usd, eur])

        s.replaceCurrency(at: 0, with: gbp)

        #expect(s.recentCurrencies[0] == gbp)
        #expect(s.baseCurrency == gbp)
    }

    // MARK: - moveCurrency

    @Test func moveToIndexZeroShiftsAndNewTopIsBase() {
        let usd = Currency.usd, eur = Currency.eur, gbp = Currency.find(code: "GBP")!
        let s = stateWith([usd, eur, gbp])

        s.moveCurrency(from: 2, to: 0)

        #expect(s.recentCurrencies == [gbp, usd, eur]) // shift, not swap
        #expect(s.baseCurrency == gbp)
    }

    // MARK: - Capacity

    @Test func selectCurrencyNeverGrowsListBeyondTen() {
        let ten = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "MXN", "CNY", "BRL"]
            .compactMap { Currency.find(code: $0) }
        let s = stateWith(ten)
        let extra = Currency.find(code: "SEK")!

        s.selectCurrency(extra)

        #expect(s.recentCurrencies.count == 10)
        #expect(s.recentCurrencies.contains(extra)) // the new one made it in
    }

    @Test func setBaseNeverGrowsListBeyondTen() {
        let ten = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "MXN", "CNY", "BRL"]
            .compactMap { Currency.find(code: $0) }
        let s = stateWith(ten)
        let newBase = Currency.find(code: "SEK")! // not in the list

        s.setBase(newBase)

        #expect(s.recentCurrencies.count == 10)
        #expect(s.recentCurrencies[0] == newBase)
    }

    @Test func setBaseHoistsAnExistingCurrencyWithoutDuplicating() {
        let usd = Currency.usd, eur = Currency.eur, gbp = Currency.find(code: "GBP")!
        let s = stateWith([usd, eur, gbp])

        s.setBase(gbp)

        #expect(s.recentCurrencies == [gbp, usd, eur])
        #expect(s.recentCurrencies.filter { $0 == gbp }.count == 1) // no duplicate
        #expect(s.baseCurrency == gbp)
    }
}
