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
    var baseCurrency: Currency = .usd

    // MARK: - MRU List (10 most recently used, excluding base currency)
    var recentCurrencies: [Currency] = []

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

    // MARK: - Init

    init() {
        decimalPlaces = UserDefaults.standard.integer(forKey: kDecimalPlaces)
        if decimalPlaces == 0 { decimalPlaces = 2 }

        widgetBaseAmount = UserDefaults.standard.string(forKey: kWidgetBase) ?? "1"
        if let code = UserDefaults.standard.string(forKey: kWidgetCurrency),
           let cur = Currency.find(code: code) {
            widgetBaseCurrency = cur
        }

        loadRecentCurrencies()

        if recentCurrencies.isEmpty {
            // Default to the most popular currencies (all supported by frankfurter.dev)
            let defaultCodes = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "MXN", "CNY", "BRL"]
            recentCurrencies = defaultCodes.compactMap { Currency.find(code: $0) }
        }

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

    // MARK: - MRU

    func selectCurrency(_ currency: Currency) {
        var mru = MRUCache<String>(capacity: 10, items: recentCurrencies.map(\.code))
        mru.use(currency.code)
        recentCurrencies = mru.items.compactMap { Currency.find(code: $0) }
        saveRecentCurrencies()
    }

    func setBaseCurrency(_ currency: Currency) {
        baseCurrency = currency
    }

    // MARK: - Base Currency Cycler

    enum CycleDirection { case up, down }

    func cycleBase(_ direction: CycleDirection) {
        guard !recentCurrencies.isEmpty else { return }
        let idx = recentCurrencies.firstIndex(of: baseCurrency) ?? -1
        let newIdx: Int
        switch direction {
        case .up:
            newIdx = idx <= 0 ? recentCurrencies.count - 1 : idx - 1
        case .down:
            newIdx = idx >= recentCurrencies.count - 1 ? 0 : idx + 1
        }
        baseCurrency = recentCurrencies[newIdx]
    }

    // MARK: - Reordering & base (index 0 is sacred: it always holds the base)

    /// Moves the currency at `sourceIndex` to `targetIndex`.
    ///
    /// Index 0 is sacred — it always holds the active base currency — so the
    /// two directions behave differently:
    ///   - Moving something *into* index 0 is a pure two-position swap with
    ///     whatever was there; every other row keeps its place.
    ///   - Moving the base *out* of index 0 (or any shift that never touches
    ///     index 0) is a plain shift. Whoever naturally ends up at index 0
    ///     afterwards becomes the base — no separate bookkeeping needed,
    ///     since index 0's occupant and `baseCurrency` are reconciled
    ///     unconditionally at the end of every move.
    func moveCurrency(from sourceIndex: Int, to targetIndex: Int) {
        guard recentCurrencies.indices.contains(sourceIndex),
              recentCurrencies.indices.contains(targetIndex),
              sourceIndex != targetIndex else { return }

        if targetIndex == 0 {
            recentCurrencies.swapAt(0, sourceIndex)
        } else {
            let moved = recentCurrencies.remove(at: sourceIndex)
            recentCurrencies.insert(moved, at: targetIndex)
        }

        baseCurrency = recentCurrencies[0]
        saveRecentCurrencies()
    }

    /// Changes the active base currency to `newBase` — the header's control,
    /// distinct from `replaceCurrency(at:with:)` which only ever touches a
    /// single row.
    ///
    /// Index 0 is sacred, so `newBase` always ends up there. If it was
    /// already a row, this is just `moveCurrency` to index 0 (a swap with
    /// the outgoing base). If it wasn't in the list at all, it's inserted at
    /// index 0 and the outgoing base takes the row right after it, so
    /// nothing is lost.
    func swapToBase(_ newBase: Currency) {
        guard newBase != baseCurrency else { return }

        if let existingIndex = recentCurrencies.firstIndex(of: newBase) {
            moveCurrency(from: existingIndex, to: 0)
            return
        }

        let oldBase = baseCurrency
        if recentCurrencies.isEmpty {
            recentCurrencies = [newBase]
        } else {
            recentCurrencies[0] = newBase
            recentCurrencies.insert(oldBase, at: 1)
        }
        baseCurrency = newBase
        saveRecentCurrencies()
    }

    // MARK: - Per-row currency swap

    /// Replaces the currency shown at `index` with `newCurrency`.
    ///
    /// If `newCurrency` is already elsewhere in the list, the two rows swap
    /// places instead of creating a duplicate — the user picked that currency
    /// deliberately, so a silent no-op or a "already in your list" toast would
    /// just be friction. If the replaced currency was the active base, the
    /// incoming currency becomes the new base too, since the base always
    /// tracks whatever currency lives at its row.
    func replaceCurrency(at index: Int, with newCurrency: Currency) {
        guard recentCurrencies.indices.contains(index) else { return }
        let oldCurrency = recentCurrencies[index]
        guard oldCurrency != newCurrency else { return }

        let wasBase = oldCurrency == baseCurrency

        if let existingIndex = recentCurrencies.firstIndex(of: newCurrency) {
            recentCurrencies.swapAt(index, existingIndex)
        } else {
            recentCurrencies[index] = newCurrency
        }

        if wasBase {
            baseCurrency = newCurrency
        }
        saveRecentCurrencies()
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
        UserDefaults.standard.set(decimalPlaces, forKey: kDecimalPlaces)
    }

    func saveWidgetSettings() {
        UserDefaults.standard.set(widgetBaseAmount, forKey: kWidgetBase)
        UserDefaults.standard.set(widgetBaseCurrency.code, forKey: kWidgetCurrency)
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
            UserDefaults.standard.set(data, forKey: kRecentCurrencies)
        }
    }

    private func loadRecentCurrencies() {
        guard let data = UserDefaults.standard.data(forKey: kRecentCurrencies),
              let codes = try? JSONDecoder().decode([String].self, from: data) else { return }
        recentCurrencies = codes.compactMap { Currency.find(code: $0) }
    }
}
