import Foundation

/// User-selectable grouping/decimal separator style.
///
/// Grouping and decimal separators are intentionally linked: a period in the
/// thousands slot forces a comma in the decimal slot (and vice versa) so the
/// output is never ambiguous (e.g. never "1.234.56").
enum SeparatorStyle: Int, CaseIterable, Identifiable {
    case commaGrouping = 0   // 1,234.56  (US / most English locales)
    case periodGrouping = 1  // 1.234,56  (most of Europe / Latin America)

    var id: Int { rawValue }

    var groupingSeparator: String { self == .commaGrouping ? "," : "." }
    var decimalSeparator: String { self == .commaGrouping ? "." : "," }
    var example: String { self == .commaGrouping ? "1,234.56" : "1.234,56" }

    /// Sensible default derived from the device locale.
    static var deviceDefault: SeparatorStyle {
        Locale.current.groupingSeparator == "." ? .periodGrouping : .commaGrouping
    }
}

enum CurrencyFormatter {
    static func format(
        _ value: Double,
        currency: Currency,
        decimalPlaces: Int = 2,
        separatorStyle: SeparatorStyle = .commaGrouping
    ) -> String {
        if currency.isCrypto {
            return formatCrypto(
                value,
                symbol: currency.symbol,
                decimalPlaces: decimalPlaces,
                separatorStyle: separatorStyle
            )
        } else {
            return formatFiat(
                value,
                code: currency.code,
                decimalPlaces: decimalPlaces,
                separatorStyle: separatorStyle
            )
        }
    }

    static func formatFiat(
        _ value: Double,
        code: String,
        decimalPlaces: Int,
        separatorStyle: SeparatorStyle = .commaGrouping
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        formatter.usesGroupingSeparator = true
        // Override both the generic and currency-specific separators so the
        // user's choice wins regardless of the ambient locale.
        formatter.groupingSeparator = separatorStyle.groupingSeparator
        formatter.decimalSeparator = separatorStyle.decimalSeparator
        formatter.currencyGroupingSeparator = separatorStyle.groupingSeparator
        formatter.currencyDecimalSeparator = separatorStyle.decimalSeparator
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func formatCrypto(
        _ value: Double,
        symbol: String,
        decimalPlaces: Int,
        separatorStyle: SeparatorStyle = .commaGrouping
    ) -> String {
        let places = max(decimalPlaces, 6)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = places
        formatter.maximumFractionDigits = places
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = separatorStyle.groupingSeparator
        formatter.decimalSeparator = separatorStyle.decimalSeparator
        let fmt = formatter.string(from: NSNumber(value: value))
            ?? String(format: "%.\(places)f", value)
        return "\(symbol) \(fmt)"
    }

    static func formatInput(_ raw: String) -> String {
        // Show exactly what the user typed, cleaning up edge cases
        if raw.isEmpty { return "0" }
        return raw
    }

    /// Formats the live keypad input for the big display: groups the integer
    /// part with the selected separator and renders the decimal separator to
    /// match, while preserving exactly what the user is mid-typing (including a
    /// trailing decimal point). The stored `inputString` always uses "." as its
    /// internal decimal marker; only the presentation changes here.
    static func groupedInput(
        _ raw: String,
        separatorStyle: SeparatorStyle = .commaGrouping
    ) -> String {
        if raw.isEmpty { return "0" }

        let dotIndex = raw.firstIndex(of: ".")
        let intPart = String(dotIndex.map { raw[raw.startIndex..<$0] } ?? Substring(raw))
        let grouped = groupInteger(intPart, separator: separatorStyle.groupingSeparator)

        guard let dotIndex else { return grouped }
        let fracPart = String(raw[raw.index(after: dotIndex)...])
        return grouped + separatorStyle.decimalSeparator + fracPart
    }

    private static func groupInteger(_ digits: String, separator: String) -> String {
        guard !digits.isEmpty else { return "0" }
        let chars = Array(digits)
        var result = ""
        for (i, c) in chars.enumerated() {
            if i > 0 && (chars.count - i) % 3 == 0 {
                result += separator
            }
            result.append(c)
        }
        return result
    }
}
