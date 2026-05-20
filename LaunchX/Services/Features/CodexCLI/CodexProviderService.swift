import Foundation
import Combine

/// Codex CLI Provider 管理服务
@MainActor
final class CodexProviderService: ObservableObject {
    static let shared = CodexProviderService()

    @Published var providers: [CodexProvider] = []
    @Published var currentProvider: CodexProvider?

    private let store = CodexDataStore.shared
    private let tomlParser = CodexTomlParser()

    private init() {
        loadData()
    }

    // MARK: - 数据加载

    private func loadData() {
        providers = store.loadProviders()
        currentProvider = providers.first { $0.isCurrent }
    }

    private func persistData() throws {
        try store.saveProviders(providers)
    }

    // MARK: - CRUD

    func addProvider(_ provider: CodexProvider) throws {
        var newProvider = provider
        newProvider.sortIndex = providers.count
        if providers.isEmpty {
            newProvider.isCurrent = true
        }
        providers.append(newProvider)
        if newProvider.isCurrent {
            currentProvider = newProvider
        }
        try persistData()
    }

    func addProvider(from preset: CodexProviderPreset, apiKey: String) throws {
        let provider = preset.createProvider(apiKey: apiKey)
        try addProvider(provider)
    }

    func updateProvider(_ provider: CodexProvider) throws {
        guard let index = providers.firstIndex(where: { $0.id == provider.id }) else { return }
        providers[index] = provider
        if provider.isCurrent {
            currentProvider = provider
            try writeCodexConfig(provider)
        }
        try persistData()
    }

    func deleteProvider(_ provider: CodexProvider) throws -> Bool {
        guard !provider.isCurrent else { return false }
        providers.removeAll { $0.id == provider.id }
        try persistData()
        return true
    }

    func getAllProviders() -> [CodexProvider] {
        providers
    }

    // MARK: - 切换 Provider

    func switchProvider(to targetProvider: CodexProvider) throws {
        guard !targetProvider.isCurrent else { return }

        let snapshot = providers.map { $0 }

        // Backfill 当前 Provider
        backfillCurrentProvider()

        // 备份当前 config.toml
        try store.backupCodexConfig()

        // 更新 isCurrent 标志
        for i in providers.indices {
            providers[i].isCurrent = (providers[i].id == targetProvider.id)
        }

        guard let activatedProvider = providers.first(where: { $0.id == targetProvider.id }) else {
            providers = snapshot
            throw ProviderSwitchError.providerNotFound
        }
        currentProvider = activatedProvider

        do {
            try writeCodexConfig(activatedProvider)
        } catch {
            providers = snapshot
            currentProvider = providers.first { $0.isCurrent }
            throw ProviderSwitchError.settingsWriteFailed(error)
        }

        do {
            try store.saveProviders(providers)
        } catch {
            throw ProviderSwitchError.persistFailed(error)
        }

        // 触发 MCP + Skills 同步
        Task { @MainActor in
            try? CodexMcpService.shared.syncToCodex()
            CodexSkillService.shared.syncAllEnabled()
        }
    }

    // MARK: - config.toml 读写

    func readCodexConfig() -> CodexTomlParser.TomlTable? {
        guard let content = store.readCodexConfig() else { return nil }
        return tomlParser.parse(content)
    }

    func writeCodexConfig(_ provider: CodexProvider) throws {
        var root: CodexTomlParser.TomlTable
        if let existing = readCodexConfig() {
            root = existing
        } else {
            root = CodexTomlParser.TomlTable()
        }

        // 更新 model_provider 字段
        root["model_provider"] = CodexTomlParser.TomlString(provider.providerId)

        // 更新 model 字段
        if let model = provider.model, !model.isEmpty {
            root["model"] = CodexTomlParser.TomlString(model)
        }

        // 写入 [model_providers.<providerId>] 段
        let providerTable = CodexTomlParser.TomlTable()
        providerTable["name"] = CodexTomlParser.TomlString(provider.name)

        if !provider.baseUrl.isEmpty {
            providerTable["base_url"] = CodexTomlParser.TomlString(provider.baseUrl)
        }

        if !provider.envKey.isEmpty {
            providerTable["env_key"] = CodexTomlParser.TomlString(provider.envKey)
        }

        if let wireApi = provider.wireApi, !wireApi.isEmpty {
            providerTable["wire_api"] = CodexTomlParser.TomlString(wireApi)
        }

        if let queryParams = provider.queryParams, !queryParams.isEmpty {
            let paramsTable = CodexTomlParser.TomlTable()
            for (key, value) in queryParams {
                paramsTable[key] = CodexTomlParser.TomlString(value)
            }
            providerTable["query_params"] = paramsTable
        }

        // 确保 model_providers 表存在
        let modelProvidersKey = "model_providers"
        if root[modelProvidersKey] == nil {
            root[modelProvidersKey] = CodexTomlParser.TomlTable()
        }
        if let mpTable = root[modelProvidersKey] as? CodexTomlParser.TomlTable {
            mpTable[provider.providerId] = providerTable
        }

        let content = tomlParser.serialize(root)
        try store.writeCodexConfig(content)
    }

    // MARK: - Backfill

    func backfillCurrentProvider() {
        guard let root = readCodexConfig() else { return }

        let currentProviderId = root["model_provider"]?.stringValue
        let model = root["model"]?.stringValue

        for i in providers.indices {
            if providers[i].isCurrent {
                if let pid = currentProviderId {
                    providers[i].providerId = pid
                }
                if let m = model {
                    providers[i].model = m
                }

                // 从 [model_providers.<id>] 段回填
                let pid = currentProviderId ?? providers[i].providerId
                if let mpTable = root["model_providers"]?.tableValue,
                   let providerEntry = mpTable[pid]?.tableValue {
                    if let baseUrl = providerEntry["base_url"]?.stringValue {
                        providers[i].baseUrl = baseUrl
                    }
                    if let envKey = providerEntry["env_key"]?.stringValue {
                        providers[i].envKey = envKey
                    }
                    if let wireApi = providerEntry["wire_api"]?.stringValue {
                        providers[i].wireApi = wireApi
                    }
                    if let name = providerEntry["name"]?.stringValue {
                        providers[i].name = name
                    }
                }

                currentProvider = providers[i]
                break
            }
        }
    }

    // MARK: - 首次导入

    func importDefaultConfig() -> CodexProvider? {
        guard let root = readCodexConfig() else { return nil }
        if !providers.isEmpty { return nil }

        let modelProvider = root["model_provider"]?.stringValue
        let model = root["model"]?.stringValue

        // 检查是否有实际配置
        guard modelProvider != nil || model != nil else { return nil }

        var provider = CodexProvider(
            name: "默认配置",
            providerId: modelProvider ?? "openai",
            baseUrl: "",
            model: model,
            category: .official,
            isCurrent: true,
            notes: "从现有 Codex CLI 配置导入"
        )

        // 从 model_providers 段回填
        if let pid = modelProvider,
           let mpTable = root["model_providers"]?.tableValue,
           let entry = mpTable[pid]?.tableValue {
            if let baseUrl = entry["base_url"]?.stringValue { provider.baseUrl = baseUrl }
            if let envKey = entry["env_key"]?.stringValue { provider.envKey = envKey }
            if let wireApi = entry["wire_api"]?.stringValue { provider.wireApi = wireApi }
            if let name = entry["name"]?.stringValue { provider.name = name }
        }

        providers.append(provider)
        currentProvider = provider
        try? persistData()
        return provider
    }

    // MARK: - 备份管理

    func listBackups() -> [URL] {
        store.listBackups()
    }

    func restoreFromBackup(_ backupURL: URL) throws {
        let content = try String(contentsOf: backupURL, encoding: .utf8)
        try store.writeCodexConfig(content)
        backfillCurrentProvider()
        try? persistData()
    }
}
