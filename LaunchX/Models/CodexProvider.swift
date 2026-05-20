import Foundation

/// Codex CLI Provider 分类
enum CodexProviderCategory: String, Codable, CaseIterable {
    case official
    case cnOfficial = "cn_official"
    case aggregator
    case thirdParty = "third_party"
    case cloudProvider = "cloud_provider"
    case local

    var displayName: String {
        switch self {
        case .official: return "官方"
        case .cnOfficial: return "国内官方"
        case .aggregator: return "聚合器"
        case .thirdParty: return "第三方"
        case .cloudProvider: return "云提供商"
        case .local: return "本地模型"
        }
    }

    var iconName: String {
        switch self {
        case .official: return "checkmark.shield"
        case .cnOfficial: return "checkmark.shield.fill"
        case .aggregator: return "square.grid.2x2"
        case .thirdParty: return "star"
        case .cloudProvider: return "cloud"
        case .local: return "desktopcomputer"
        }
    }
}

/// Codex CLI Provider 配置模型
struct CodexProvider: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var providerId: String         // TOML 中的 provider 标识符，如 "openai", "mistral"
    var baseUrl: String            // API 端点
    var envKey: String             // API Key 环境变量名，如 "OPENAI_API_KEY"
    var apiKey: String             // 用户填写的 API Key
    var wireApi: String?           // 通信协议: "responses" 或 "chat_completions"
    var queryParams: [String: String]? // URL 查询参数
    var model: String?             // 默认模型
    var category: CodexProviderCategory
    var isCurrent: Bool
    var sortIndex: Int
    var notes: String?
    var icon: String?
    var iconColor: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        providerId: String,
        baseUrl: String = "",
        envKey: String = "OPENAI_API_KEY",
        apiKey: String = "",
        wireApi: String? = nil,
        queryParams: [String: String]? = nil,
        model: String? = nil,
        category: CodexProviderCategory = .thirdParty,
        isCurrent: Bool = false,
        sortIndex: Int = 0,
        notes: String? = nil,
        icon: String? = nil,
        iconColor: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.providerId = providerId
        self.baseUrl = baseUrl
        self.envKey = envKey
        self.apiKey = apiKey
        self.wireApi = wireApi
        self.queryParams = queryParams
        self.model = model
        self.category = category
        self.isCurrent = isCurrent
        self.sortIndex = sortIndex
        self.notes = notes
        self.icon = icon
        self.iconColor = iconColor
        self.createdAt = createdAt
    }
}
