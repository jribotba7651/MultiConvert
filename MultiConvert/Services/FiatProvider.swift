import Foundation

/// Fetches fiat exchange rates from frankfurter.app (open-source, free, no API key).
/// Returns rates as units-per-USD: e.g., EUR → 0.926 means 1 USD = 0.926 EUR.
final class FiatProvider: RateProvider {
    let supportedCodes: Set<String> = [
        "USD", "EUR", "JPY", "MXN", "GBP", "CAD", "AUD", "CHF", "CNY", "KRW", "BRL"
    ]

    func fetchRatesPerUSD() async throws -> [String: Double] {
        guard let url = URL(string: "https://api.frankfurter.app/latest?base=USD") else {
            throw ProviderError.networkUnavailable
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw ProviderError.badResponse(0)
        }
        guard http.statusCode == 200 else {
            throw ProviderError.badResponse(http.statusCode)
        }
        let decoded: FrankfurterResponse
        do {
            decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        } catch {
            throw ProviderError.decodingFailed(error.localizedDescription)
        }
        var rates = decoded.rates
        rates["USD"] = 1.0
        return rates
    }
}

private struct FrankfurterResponse: Decodable {
    let rates: [String: Double]
}
