import Foundation

/// Persists the last successful RateSnapshot to the Caches directory as JSON.
final class RateCache {
    private let fileURL: URL

    init(filename: String = "multiconvert_rates.json") {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent(filename)
    }

    var snapshot: RateSnapshot? {
        load()
    }

    func save(_ snapshot: RateSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Private

    private func load() -> RateSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(RateSnapshot.self, from: data)
    }
}
