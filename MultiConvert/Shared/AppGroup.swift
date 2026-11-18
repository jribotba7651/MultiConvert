import Foundation

/// Storage shared between the app and the widget extension through the
/// `group.com.jibaroenlaluna.multiconvert` App Group.
///
/// Compiled into both targets. If the group container is unavailable (e.g.
/// the App Group isn't provisioned yet) everything falls back to the
/// app-local `UserDefaults.standard` / Caches directory so the app keeps
/// working; only the widget loses access to live data in that case.
enum AppGroup {
    static let identifier = "group.com.jibaroenlaluna.multiconvert"

    enum Keys {
        static let recentCurrencies = "recentCurrencies_v2"
        static let decimalPlaces    = "decimalPlaces"
        static let separatorStyle   = "separatorStyle"
        static let widgetBase       = "widgetBaseAmount"
        static let widgetCurrency   = "widgetBaseCurrency"
        static let didMigrate       = "didMigrateToAppGroup_v1"

        /// Keys that moved from `UserDefaults.standard` into the group suite.
        static let migrated = [recentCurrencies, decimalPlaces, separatorStyle, widgetBase, widgetCurrency]
    }

    static let rateCacheFilename = "multiconvert_rates.json"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    /// Directory for shared files (the rate cache). Group container when
    /// available, otherwise the local Caches directory.
    static var containerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            return url
        }
        return localCachesURL
    }

    static var localCachesURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    /// One-time move of pre-1.0.2 data (settings in `UserDefaults.standard`,
    /// rate cache in the app's Caches directory) into the shared group.
    /// Safe to call on every launch; it only does work once.
    static func migrateLegacyDataIfNeeded() {
        let shared = defaults
        guard shared !== UserDefaults.standard,
              !shared.bool(forKey: Keys.didMigrate) else { return }

        let legacy = UserDefaults.standard
        for key in Keys.migrated where shared.object(forKey: key) == nil {
            if let value = legacy.object(forKey: key) {
                shared.set(value, forKey: key)
            }
        }

        let fm = FileManager.default
        let oldCache = localCachesURL.appendingPathComponent(rateCacheFilename)
        let newCache = containerURL.appendingPathComponent(rateCacheFilename)
        if oldCache != newCache,
           fm.fileExists(atPath: oldCache.path),
           !fm.fileExists(atPath: newCache.path) {
            try? fm.copyItem(at: oldCache, to: newCache)
        }

        shared.set(true, forKey: Keys.didMigrate)
    }
}
