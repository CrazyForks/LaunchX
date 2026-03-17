import Foundation

// MARK: - Reminders Settings

struct RemindersSettings: Codable {
    var isEnabled: Bool

    private static let userDefaultsKey = "remindersEnabled"

    static let `default` = RemindersSettings(isEnabled: false)

    static func load() -> RemindersSettings {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let settings = try? JSONDecoder().decode(RemindersSettings.self, from: data)
        {
            return settings
        }
        return .default
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: RemindersSettings.userDefaultsKey)
        }
    }
}
