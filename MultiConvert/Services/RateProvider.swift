import Foundation

protocol RateProvider {
    /// Returns rates as "units per USD". E.g., EUR → 0.92 means 1 USD = 0.92 EUR.
    func fetchRatesPerUSD() async throws -> [String: Double]
    var supportedCodes: Set<String> { get }
}

enum ProviderError: LocalizedError {
    case badResponse(Int)
    case decodingFailed(String)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .badResponse(let code): "Server returned \(code)"
        case .decodingFailed(let detail): "Could not parse response: \(detail)"
        case .networkUnavailable: "Network unavailable"
        }
    }
}
