import Foundation

enum CurrencyType: String, Codable, Hashable, CaseIterable {
    case fiat
    case crypto
}

struct Currency: Identifiable, Hashable, Codable {
    let code: String
    let name: String
    let symbol: String
    let type: CurrencyType
    let flag: String?

    var id: String { code }
    var isCrypto: Bool { type == .crypto }
}

extension Currency {
    static let allFiat: [Currency] = [
        Currency(code: "USD", name: "US Dollar",         symbol: "$",  type: .fiat, flag: "🇺🇸"),
        Currency(code: "EUR", name: "Euro",               symbol: "€",  type: .fiat, flag: "🇪🇺"),
        Currency(code: "JPY", name: "Japanese Yen",       symbol: "¥",  type: .fiat, flag: "🇯🇵"),
        Currency(code: "MXN", name: "Mexican Peso",       symbol: "$",  type: .fiat, flag: "🇲🇽"),
        Currency(code: "GBP", name: "British Pound",      symbol: "£",  type: .fiat, flag: "🇬🇧"),
        Currency(code: "CAD", name: "Canadian Dollar",    symbol: "$",  type: .fiat, flag: "🇨🇦"),
        Currency(code: "AUD", name: "Australian Dollar",  symbol: "$",  type: .fiat, flag: "🇦🇺"),
        Currency(code: "CHF", name: "Swiss Franc",        symbol: "Fr", type: .fiat, flag: "🇨🇭"),
        Currency(code: "CNY", name: "Chinese Yuan",       symbol: "¥",  type: .fiat, flag: "🇨🇳"),
        Currency(code: "KRW", name: "South Korean Won",   symbol: "₩",  type: .fiat, flag: "🇰🇷"),
        Currency(code: "BRL", name: "Brazilian Real",     symbol: "R$", type: .fiat, flag: "🇧🇷"),
    ]

    static let allCrypto: [Currency] = [
        Currency(code: "BTC",  name: "Bitcoin",   symbol: "₿", type: .crypto, flag: nil),
        Currency(code: "ETH",  name: "Ethereum",  symbol: "Ξ", type: .crypto, flag: nil),
        Currency(code: "SOL",  name: "Solana",    symbol: "◎", type: .crypto, flag: nil),
        Currency(code: "USDC", name: "USD Coin",  symbol: "◈", type: .crypto, flag: nil),
        Currency(code: "USDT", name: "Tether",    symbol: "₮", type: .crypto, flag: nil),
    ]

    static let all: [Currency] = allFiat + allCrypto

    static func find(code: String) -> Currency? {
        all.first { $0.code == code }
    }

    static var usd: Currency { find(code: "USD")! }
    static var eur: Currency { find(code: "EUR")! }
    static var btc: Currency { find(code: "BTC")! }
}
