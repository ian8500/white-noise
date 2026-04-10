import Foundation

public final class UserDefaultsSettingsStore: SettingsStoring {
    private enum Keys {
        static let settings = "dreamnest.settings"
        static let cryEvents = "dreamnest.cryEvents"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AppSettings {
        guard let data = defaults.data(forKey: Keys.settings),
              let settings = try? decoder.decode(AppSettings.self, from: data)
        else { return AppSettings() }
        return settings
    }

    public func save(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: Keys.settings)
    }

    public func appendCryEvent(_ event: CryDetectionEvent) {
        var existing = loadCryEvents(limit: 250)
        existing.insert(event, at: 0)
        let capped = Array(existing.prefix(250))
        guard let data = try? encoder.encode(capped) else { return }
        defaults.set(data, forKey: Keys.cryEvents)
    }

    public func loadCryEvents(limit: Int = 30) -> [CryDetectionEvent] {
        guard let data = defaults.data(forKey: Keys.cryEvents),
              let events = try? decoder.decode([CryDetectionEvent].self, from: data)
        else { return [] }
        return Array(events.prefix(max(0, limit)))
    }

    public func clearCryEvents() {
        defaults.removeObject(forKey: Keys.cryEvents)
    }
}
