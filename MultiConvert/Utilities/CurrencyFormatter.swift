import Foundation

enum CurrencyFormatter {
    static func format(
        _ value: Double,
        currency: Currency,
        decimalPlaces: Int = 2
    ) -> String {
        if currency.isCrypto {
            return formatCrypto(value, symbol: currency.symbol, decimalPlaces: decimalPlaces)
        } else {
            return formatFiat(value, code: currency.code, decimalPlaces: decimalPlaces)
        }
    }

    static func formatFiat(_ value: Double, code: String, decimalPlaces: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func formatCrypto(_ value: Double, symbol: String, decimalPlaces: Int) -> String {
        let places = max(decimalPlaces, 6)
        let fmt = String(format: "%.\(places)f", value)
        return "\(symbol) \(fmt)"
    }

    static func formatInput(_ raw: String) -> String {
        // Show exactly what the user typed, cleaning up edge cases
        if raw.isEmpty { return "0" }
        return raw
    }
}
