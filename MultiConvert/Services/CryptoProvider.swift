import Foundation

/// Fetches crypto prices from CoinGecko free tier (no API key).
/// Converts CoinGecko USD prices to units-per-USD format:
///   If 1 BTC = 65,000 USD, then ratesPerUSD["BTC"] = 1/65000 ≈ 0.0000154
final class CryptoProvider: RateProvider {
    let supportedCodes: Set<String> = ["BTC", "ETH", "SOL", "USDC", "USDT"]

    private let codeToId: [String: String] = [
        "BTC":  "bitcoin",
        "ETH":  "ethereum",
        "SOL":  "solana",
        "USDC": "usd-coin",
        "USDT": "tether",
    ]

    func fetchRatesPerUSD() async throws -> [String: Double] {
        let ids = codeToId.values.sorted().joined(separator: ",")
        let urlStr = "https://api.coingecko.com/api/v3/simple/price?ids=\(ids)&vs_currencies=usd"
        guard let url = URL(string: urlStr) else { throw ProviderError.networkUnavailable }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw ProviderError.badResponse(0)
        }
        guard http.statusCode == 200 else {
            throw ProviderError.badResponse(http.statusCode)
        }

        // Response: { "bitcoin": { "usd": 65000 }, "ethereum": { "usd": 3500 }, … }
        let raw: [String: [String: Double]]
        do {
            raw = try JSONDecoder().decode([String: [String: Double]].self, from: data)
        } catch {
            throw ProviderError.decodingFailed(error.localizedDescription)
        }

        var rates: [String: Double] = [:]
        for (code, coinId) in codeToId {
            if let priceUSD = raw[coinId]?["usd"], priceUSD > 0 {
                rates[code] = 1.0 / priceUSD
            }
        }
        return rates
    }
}
