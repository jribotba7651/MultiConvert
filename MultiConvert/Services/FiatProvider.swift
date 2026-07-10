import Foundation

/// Fetches fiat exchange rates from exchangerate-api.com (free, no API key, 160+ currencies).
/// Returns rates as units-per-USD: e.g., EUR → 0.926 means 1 USD = 0.926 EUR.
final class FiatProvider: RateProvider {
    let supportedCodes: Set<String> = Set(Currency.allFiat.map(\.code))

    func fetchRatesPerUSD() async throws -> [String: Double] {
        guard let url = URL(string: "https://api.exchangerate-api.com/v4/latest/USD") else {
            throw ProviderError.networkUnavailable
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw ProviderError.badResponse(0)
        }
        guard http.statusCode == 200 else {
            throw ProviderError.badResponse(http.statusCode)
        }
        do {
            let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            return decoded.rates
        } catch {
            throw ProviderError.decodingFailed(error.localizedDescription)
        }
    }
}

private struct ExchangeRateResponse: Decodable {
    let rates: [String: Double]
}
