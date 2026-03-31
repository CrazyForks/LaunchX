import Foundation

/// Claude Code Switcher 搜索面板配置
struct ClaudeCodeSwitcherSettings: Codable {
    var isEnabled: Bool
    var alias: String  // 别名，如 "cc"
    var hotKeyCode: UInt32
    var hotKeyModifiers: UInt32

    static let `default` = ClaudeCodeSwitcherSettings(
        isEnabled: true,
        alias: "cc",
        hotKeyCode: 0,
        hotKeyModifiers: 0
    )

    private static let storageKey = "claudeCodeSwitcherSettings"

    static func load() -> ClaudeCodeSwitcherSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(ClaudeCodeSwitcherSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: ClaudeCodeSwitcherSettings.storageKey)
        }
    }
}
