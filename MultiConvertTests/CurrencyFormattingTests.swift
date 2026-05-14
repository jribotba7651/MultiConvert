import Testing
import Foundation
import SwiftUI
@testable import MultiConvert

@Suite("Currency Formatting")
struct CurrencyFormattingTests {
    @Test func fiatUSDFormat() {
        let result = CurrencyFormatter.formatFiat(1234.56, code: "USD", decimalPlaces: 2)
        #expect(result.contains("1,234"))
        #expect(result.contains("56"))
    }

    @Test func fiatEURFormat() {
        let result = CurrencyFormatter.formatFiat(99.9, code: "EUR", decimalPlaces: 2)
        #expect(result.contains("99"))
        #expect(!result.isEmpty)
    }

    @Test func fiatJPYLargeValue() {
        let result = CurrencyFormatter.formatFiat(1_490_000, code: "JPY", decimalPlaces: 2)
        #expect(!result.isEmpty)
        // JPY doesn't use decimals in practice but formatter respects decimalPlaces
    }

    @Test func fiatFourDecimalPlaces() {
        let result = CurrencyFormatter.formatFiat(1.23456789, code: "USD", decimalPlaces: 4)
        #expect(result.contains("1.2346") || result.contains("1,2346") || result.contains("1.2345"))
    }

    @Test func cryptoFormatSmallValue() {
        let result = CurrencyFormatter.formatCrypto(0.00001540, symbol: "₿", decimalPlaces: 2)
        #expect(result.contains("₿"))
        #expect(result.contains("0.000015") || result.contains("0.00001"))
    }

    @Test func cryptoFormatWithSixDecimals() {
        let result = CurrencyFormatter.formatCrypto(1.0 / 65_000, symbol: "₿", decimalPlaces: 2)
        #expect(result.contains("₿"))
    }

    @Test func formatDispatchFiat() {
        let usd = Currency.find(code: "USD")!
        let result = CurrencyFormatter.format(100.0, currency: usd, decimalPlaces: 2)
        #expect(result.contains("100"))
    }

    @Test func formatDispatchCrypto() {
        let btc = Currency.find(code: "BTC")!
        let result = CurrencyFormatter.format(0.001, currency: btc, decimalPlaces: 2)
        #expect(result.contains("₿"))
    }

    @Test func formatInputEmptyIsZero() {
        #expect(CurrencyFormatter.formatInput("") == "0")
    }

    @Test func formatInputNonEmpty() {
        #expect(CurrencyFormatter.formatInput("123") == "123")
    }

    @Test func zeroCurrency() {
        let usd = Currency.find(code: "USD")!
        let result = CurrencyFormatter.format(0.0, currency: usd, decimalPlaces: 2)
        #expect(result.contains("0"))
    }

    @Test func allCurrenciesHaveUniqueIDs() {
        let ids = Currency.all.map(\.id)
        let unique = Set(ids)
        #expect(ids.count == unique.count)
    }

    @Test func cryptoCurrenciesIdentified() {
        #expect(Currency.find(code: "BTC")?.isCrypto == true)
        #expect(Currency.find(code: "ETH")?.isCrypto == true)
        #expect(Currency.find(code: "USD")?.isCrypto == false)
    }

    @Test func allRequiredFiatPresent() {
        let required = ["USD", "EUR", "JPY", "MXN", "GBP", "CAD", "AUD", "CHF", "CNY", "KRW", "BRL"]
        for code in required {
            #expect(Currency.find(code: code) != nil, "Missing fiat: \(code)")
        }
    }

    @Test func allRequiredCryptoPresent() {
        let required = ["BTC", "ETH", "SOL", "USDC", "USDT"]
        for code in required {
            #expect(Currency.find(code: code) != nil, "Missing crypto: \(code)")
        }
    }
}
