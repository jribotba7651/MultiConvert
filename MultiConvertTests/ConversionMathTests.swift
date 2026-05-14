import Testing
import Foundation
@testable import MultiConvert

@Suite("Conversion Math")
struct ConversionMathTests {
    let snapshot = RateSnapshot(
        ratesPerUSD: [
            "USD": 1.0,
            "EUR": 0.926,
            "JPY": 149.2,
            "GBP": 0.789,
            "BTC": 1.0 / 65_000,
            "ETH": 1.0 / 3_500,
        ],
        fetchedAt: Date()
    )

    @Test func usdToEur() {
        let result = snapshot.convert(amount: 100, from: "USD", to: "EUR")
        #expect(result != nil)
        #expect(abs(result! - 92.6) < 0.001)
    }

    @Test func eurToUsd() {
        let result = snapshot.convert(amount: 92.6, from: "EUR", to: "USD")
        #expect(result != nil)
        #expect(abs(result! - 100.0) < 0.01)
    }

    @Test func usdToBtc() {
        let result = snapshot.convert(amount: 65_000, from: "USD", to: "BTC")
        #expect(result != nil)
        #expect(abs(result! - 1.0) < 0.000001)
    }

    @Test func btcToUsd() {
        let result = snapshot.convert(amount: 1.0, from: "BTC", to: "USD")
        #expect(result != nil)
        #expect(abs(result! - 65_000) < 0.01)
    }

    @Test func btcToEth() {
        // 1 BTC = 65000 USD, 1 ETH = 3500 USD → 1 BTC ≈ 18.57 ETH
        let result = snapshot.convert(amount: 1.0, from: "BTC", to: "ETH")
        #expect(result != nil)
        let expected = 65_000.0 / 3_500.0
        #expect(abs(result! - expected) < 0.001)
    }

    @Test func selfConversionIsIdentity() {
        let result = snapshot.convert(amount: 42.5, from: "USD", to: "USD")
        #expect(result != nil)
        #expect(abs(result! - 42.5) < 0.000001)
    }

    @Test func missingCurrencyReturnsNil() {
        let result = snapshot.convert(amount: 100, from: "USD", to: "XYZ")
        #expect(result == nil)
    }

    @Test func zeroAmountConverts() {
        let result = snapshot.convert(amount: 0, from: "USD", to: "EUR")
        #expect(result != nil)
        #expect(result! == 0.0)
    }

    @Test func jpyLargeAmount() {
        // 100 USD → 14920 JPY
        let result = snapshot.convert(amount: 100, from: "USD", to: "JPY")
        #expect(result != nil)
        #expect(abs(result! - 14_920) < 0.1)
    }
}
