import Foundation
import Combine

/// Claude Code Provider 管理服务
@MainActor
final class ClaudeProviderService: ObservableObject {
    static let shared = ClaudeProviderService()

    @Published var providers: [ClaudeProvider] = []
    @Published var currentProvider: ClaudeProvider?

    private let store = ClaudeDataStore.shared
    private let fileManager = FileManager.default

    private init() {
        loadData()
    }

    // MARK: - 数据加载

    private func loadData() {
        providers = store.loadProviders()
        currentProvider = providers.first { $0.isCurrent }
    }

    private func persistData() {
        try? store.saveProviders(providers)
    }

    // MARK: - Claude Code 配置文件路径

    private var claudeSettingsPath: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".claude/settings.json")
    }

    // MARK: - CRUD

    /// 添加 Provider
    func addProvider(_ provider: ClaudeProvider) {
        var newProvider = provider
        newProvider.sortIndex = providers.count
        if providers.isEmpty {
            newProvider.isCurrent = true
        }
        providers.append(newProvider)
        if newProvider.isCurrent {
            currentProvider = newProvider
        }
        persistData()
    }

    /// 从预设添加 Provider
    func addProvider(from preset: ClaudeProviderPreset, apiKey: String) {
        let provider = preset.createProvider(apiKey: apiKey)
        addProvider(provider)
    }

    /// 更新 Provider
    func updateProvider(_ provider: ClaudeProvider) {
        guard let index = providers.firstIndex(where: { $0.id == provider.id }) else { return }
        providers[index] = provider
        if provider.isCurrent {
            currentProvider = provider
            writeClaudeSettings(provider)
        }
        persistData()
    }

    /// 删除 Provider
    func deleteProvider(_ provider: ClaudeProvider) -> Bool {
        guard !provider.isCurrent else { return false }
        providers.removeAll { $0.id == provider.id }
        persistData()
        return true
    }

    /// 获取所有 Provider
    func getAllProviders() -> [ClaudeProvider] {
        providers
    }

    // MARK: - 切换 Provider

    /// 切换到指定 Provider
    func switchProvider(to targetProvider: ClaudeProvider) throws {
        guard !targetProvider.isCurrent else { return }

        // 1. Backfill: 读取当前 settings.json 回填到旧 Provider
        backfillCurrentProvider()

        // 2. 备份当前配置
        try store.backupClaudeSettings()

        // 3. 更新 isCurrent 标志
        for i in providers.indices {
            providers[i].isCurrent = (providers[i].id == targetProvider.id)
        }

        // 4. 获取切换目标（更新后的）
        guard let activatedProvider = providers.first(where: { $0.id == targetProvider.id }) else {
            return
        }
        currentProvider = activatedProvider

        // 5. 写入新配置
        writeClaudeSettings(activatedProvider)

        // 6. 持久化
        persistData()

        // 7. 触发 MCP 同步
        Task { @MainActor in
            ClaudeMcpService.shared.syncToClaude()
        }

        // 8. 触发 Skills 同步
        Task { @MainActor in
            ClaudeSkillService.shared.syncAllEnabled()
        }
    }

    // MARK: - 配置读写

    /// 读取 ~/.claude/settings.json
    func readClaudeSettings() -> [String: Any]? {
        guard fileManager.fileExists(atPath: claudeSettingsPath.path),
              let data = try? Data(contentsOf: claudeSettingsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }

    /// 原子写入 ~/.claude/settings.json
    func writeClaudeSettings(_ provider: ClaudeProvider) {
        // 读取现有配置（保留非 env 字段）
        var existingConfig = readClaudeSettings() ?? [:]

        // 更新 env 字段
        existingConfig["env"] = provider.settingsConfig

        // 剥离内部字段
        let sanitized = sanitizeForLive(existingConfig)

        guard let jsonData = try? JSONSerialization.data(
            withJSONObject: sanitized, options: [.prettyPrinted, .sortedKeys]) else {
            return
        }

        // 原子写入
        let tempPath = claudeSettingsPath.deletingLastPathComponent()
            .appendingPathComponent(".tmp_settings_\(UUID().uuidString)")
        do {
            try jsonData.write(to: tempPath, options: .atomic)
            try fileManager.moveItem(at: tempPath, to: claudeSettingsPath)
        } catch {
            try? fileManager.removeItem(at: tempPath)
        }
    }

    /// 剥离内部字段（不应写入 Claude Code 配置的字段）
    private func sanitizeForLive(_ config: [String: Any]) -> [String: Any] {
        var result = config
        if var env = result["env"] as? [String: Any] {
            let internalKeys = ["apiFormat", "apiBaseUrl", "primaryModel", "smallFastModel",
                                "openrouterCompatMode", "DISABLE_NONESSENTIAL_TRAFFIC"]
            for key in internalKeys {
                env.removeValue(forKey: key)
            }
            result["env"] = env
        }
        return result
    }

    // MARK: - Backfill

    /// 回填当前 settings.json 配置到当前激活的 Provider
    func backfillCurrentProvider() {
        guard let liveSettings = readClaudeSettings(),
              let liveEnv = liveSettings["env"] as? [String: Any] else {
            return
        }

        // 将 [String: Any] 转换为 [String: String]
        let stringEnv = liveEnv.compactMapValues { value -> String? in
            if let str = value as? String { return str }
            if let num = value as? NSNumber { return num.stringValue }
            return nil
        }

        // 更新当前 Provider
        for i in providers.indices {
            if providers[i].isCurrent {
                providers[i].settingsConfig = stringEnv
                currentProvider = providers[i]
                break
            }
        }
    }

    // MARK: - 首次导入

    /// 导入已有的 Claude Code 配置为默认 Provider
    func importDefaultConfig() -> ClaudeProvider? {
        guard let liveSettings = readClaudeSettings(),
              let liveEnv = liveSettings["env"] as? [String: Any] else {
            return nil
        }

        // 检查是否已有 Provider
        if !providers.isEmpty { return nil }

        let stringEnv = liveEnv.compactMapValues { value -> String? in
            if let str = value as? String { return str }
            if let num = value as? NSNumber { return num.stringValue }
            return nil
        }

        // 只有当有实际配置时才导入
        let hasApiKey = stringEnv["ANTHROPIC_AUTH_TOKEN"] != nil || stringEnv["ANTHROPIC_API_KEY"] != nil
        let hasBaseUrl = stringEnv["ANTHROPIC_BASE_URL"] != nil

        guard hasApiKey || hasBaseUrl else { return nil }

        let defaultProvider = ClaudeProvider(
            name: "默认配置",
            settingsConfig: stringEnv,
            category: .official,
            notes: "从现有 Claude Code 配置导入",
            isCurrent: true
        )
        providers.append(defaultProvider)
        currentProvider = defaultProvider
        persistData()
        return defaultProvider
    }

    // MARK: - 备份管理

    /// 获取备份列表
    func listBackups() -> [URL] {
        store.listBackups()
    }

    /// 从备份恢复
    func restoreFromBackup(_ backupURL: URL) throws {
        guard let data = try? Data(contentsOf: backupURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            .write(to: claudeSettingsPath, options: .atomic)

        // 回填到当前 Provider
        backfillCurrentProvider()
        persistData()
    }
}
