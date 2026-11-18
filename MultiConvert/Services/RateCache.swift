import Foundation

/// Persists the last successful RateSnapshot as JSON in the shared App Group
/// container, so the widget extension reads the same rates as the app.
final class RateCache {
    private let fileURL: URL

    init(
        filename: String = AppGroup.rateCacheFilename,
        directory: URL = AppGroup.containerURL
    ) {
        fileURL = directory.appendingPathComponent(filename)
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
