import Foundation
import Observation

private let kRecentCurrencies = "recentCurrencies_v2"
private let kDecimalPlaces    = "decimalPlaces"
private let kWidgetBase       = "widgetBaseAmount"
private let kWidgetCurrency   = "widgetBaseCurrency"

@Observable
final class AppState {
    // MARK: - Input
    var inputString: String = "0"

    // MARK: - Currency list & base (single source of truth)
    //
    // `recentCurrencies[0]` IS the base currency — there is no separately
    // stored base, so the "index 0 holds the base" invariant cannot drift out
    // of sync with the list. Persisting the list alone therefore restores the
    // base across launches. Every production mutation routes through
    // `commit(_:)`, which dedupes, clamps to the 10-item cap, and persists;
    // no other code assigns to `recentCurrencies` directly.
    var recentCurrencies: [Currency] = []

    /// The active base currency: always whatever occupies the top slot.
    var baseCurrency: Currency { recentCurrencies.first ?? .usd }

    private static let listCapacity = 10
    private static let defaultCurrencyCodes =
        ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "MXN", "CNY", "BRL"]
    private static var defaultCurrencies: [Currency] {
        defaultCurrencyCodes.compactMap { Currency.find(code: $0) }
    }

    // MARK: - Rates
    var snapshot: RateSnapshot?
    var isLoading: Bool = false
    var fetchError: String?

    // MARK: - Settings
    var decimalPlaces: Int = 2
    var widgetBaseAmount: String = "1"
    var widgetBaseCurrency: Currency = .usd

    // MARK: - Engine
    private let engine = ConversionEngine()

    // Injectable so tests can isolate persistence from UserDefaults.standard;
    // production always uses .standard.
    private let defaults: UserDefaults

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        decimalPlaces = defaults.integer(forKey: kDecimalPlaces)
        if decimalPlaces == 0 { decimalPlaces = 2 }

        widgetBaseAmount = defaults.string(forKey: kWidgetBase) ?? "1"
        if let code = defaults.string(forKey: kWidgetCurrency),
           let cur = Currency.find(code: code) {
            widgetBaseCurrency = cur
        }

        // Whatever was persisted (or the default seed) is run back through the
        // same funnel every mutation uses, so a list saved by an older build
        // that grew past the cap or accumulated duplicates is healed on launch.
        let loaded = loadPersistedCurrencies()
        commit(loaded.isEmpty ? Self.defaultCurrencies : loaded)

        snapshot = engine.cachedSnapshot
    }

    // MARK: - Computed

    var baseAmount: Double {
        Double(inputString.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    var isStale: Bool {
        snapshot?.isStale ?? true
    }

    var lastUpdated: Date? {
        snapshot?.fetchedAt
    }

    // MARK: - Conversion

    func convertedValue(for currency: Currency) -> Double? {
        snapshot?.convert(amount: baseAmount, from: baseCurrency.code, to: currency.code)
    }

    // MARK: - Mutation funnel
    //
    // The single point where `recentCurrencies` is written. Callers assemble
    // the ordering they want and hand it here; this dedupes (first occurrence
    // of each code wins, preserving order), clamps to `listCapacity`, and
    // persists. Routing everything through here is what guarantees the cap and
    // the no-duplicates invariant no matter which entry point ran.
    private func commit(_ proposed: [Currency]) {
        var seen = Set<String>()
        var deduped: [Currency] = []
        for currency in proposed where seen.insert(currency.code).inserted {
            deduped.append(currency)
        }
        recentCurrencies = Array(deduped.prefix(Self.listCapacity))
        saveRecentCurrencies()
    }

    // MARK: - Add (header "+")

    /// The picked currency joins just below the base at index 1 — never at
    /// index 0, so it can't displace the base. If it's already in the list it
    /// moves to index 1; if it's the current base, nothing changes.
    func selectCurrency(_ currency: Currency) {
        guard currency != baseCurrency else { return }
        var list = recentCurrencies
        list.removeAll { $0 == currency }
        list.insert(currency, at: min(1, list.count))
        commit(list)
    }

    // MARK: - Base (header base button)

    /// Makes `newBase` the active base by hoisting it to index 0. Works whether
    /// or not it's already in the list; the outgoing base shifts down to index
    /// 1 and is never lost.
    func setBase(_ newBase: Currency) {
        guard newBase != baseCurrency else { return }
        var list = recentCurrencies
        list.removeAll { $0 == newBase }
        list.insert(newBase, at: 0)
        commit(list)
    }

    // MARK: - Reorder (drag)

    /// Pure shift (remove + insert), identical for every target including
    /// index 0, so the committed order matches the drag preview exactly.
    /// Whatever lands at index 0 becomes the base by definition.
    func moveCurrency(from source: Int, to target: Int) {
        guard recentCurrencies.indices.contains(source),
              recentCurrencies.indices.contains(target),
              source != target else { return }
        var list = recentCurrencies
        let moved = list.remove(at: source)
        list.insert(moved, at: target)
        commit(list)
    }

    // MARK: - Per-row currency swap

    /// Swaps the currency shown at `index` for `newCurrency`. Replacing the
    /// index-0 row is a legitimate base change. If `newCurrency` already sits
    /// in another row (including the base row), the two rows swap positions —
    /// so the base slot always stays filled and no duplicate is created.
    func replaceCurrency(at index: Int, with newCurrency: Currency) {
        guard recentCurrencies.indices.contains(index) else { return }
        guard recentCurrencies[index] != newCurrency else { return }
        var list = recentCurrencies
        if let existing = list.firstIndex(of: newCurrency) {
            list.swapAt(index, existing)
        } else {
            list[index] = newCurrency
        }
        commit(list)
    }

    // MARK: - Refresh

    @MainActor
    func refresh() async {
        isLoading = true
        fetchError = nil
        do {
            snapshot = try await engine.fetchRates()
        } catch {
            fetchError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Keypad

    func appendDigit(_ digit: String) {
        if inputString == "0" && digit != "." {
            inputString = digit
        } else if digit == "." && inputString.contains(".") {
            return
        } else if inputString.count < 15 {
            inputString.append(digit)
        }
    }

    func deleteLastDigit() {
        if inputString.count <= 1 {
            inputString = "0"
        } else {
            inputString.removeLast()
        }
    }

    func clearInput() {
        inputString = "0"
    }

    // MARK: - Settings persistence

    func saveDecimalPlaces() {
        defaults.set(decimalPlaces, forKey: kDecimalPlaces)
    }

    func saveWidgetSettings() {
        defaults.set(widgetBaseAmount, forKey: kWidgetBase)
        defaults.set(widgetBaseCurrency.code, forKey: kWidgetCurrency)
        // Notify widget to reload
        #if canImport(WidgetKit)
        // WidgetCenter.shared.reloadAllTimelines()  // imported in widget target
        #endif
    }

    func clearCache() {
        engine.clearCache()
        snapshot = nil
    }

    // MARK: - Persistence

    private func saveRecentCurrencies() {
        let codes = recentCurrencies.map(\.code)
        if let data = try? JSONEncoder().encode(codes) {
            defaults.set(data, forKey: kRecentCurrencies)
        }
    }

    private func loadPersistedCurrencies() -> [Currency] {
        guard let data = defaults.data(forKey: kRecentCurrencies),
              let codes = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return codes.compactMap { Currency.find(code: $0) }
    }
}
