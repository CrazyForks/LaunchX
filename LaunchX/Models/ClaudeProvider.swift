import Foundation

// MARK: - Provider 分类

/// Provider 分类
enum ClaudeProviderCategory: String, Codable, CaseIterable {
    case official
    case cnOfficial = "cn_official"
    case aggregator
    case thirdParty = "third_party"
    case cloudProvider = "cloud_provider"

    var displayName: String {
        switch self {
        case .official: return "官方"
        case .cnOfficial: return "国内官方"
        case .aggregator: return "聚合平台"
        case .thirdParty: return "第三方"
        case .cloudProvider: return "云服务商"
        }
    }

    var iconName: String {
        switch self {
        case .official: return "checkmark.shield"
        case .cnOfficial: return "checkmark.shield.fill"
        case .aggregator: return "square.grid.2x2"
        case .thirdParty: return "star"
        case .cloudProvider: return "cloud"
        }
    }
}

// MARK: - Claude Provider

/// Claude Code Provider 数据模型
struct ClaudeProvider: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var settingsConfig: [String: String]  // env 变量（ANTHROPIC_AUTH_TOKEN, ANTHROPIC_BASE_URL 等）
    var category: ClaudeProviderCategory
    var websiteUrl: String?
    var notes: String?
    var icon: String?
    var iconColor: String?
    var isCurrent: Bool
    var createdAt: Date
    var sortIndex: Int

    init(
        id: UUID = UUID(),
        name: String,
        settingsConfig: [String: String] = [:],
        category: ClaudeProviderCategory = .thirdParty,
        websiteUrl: String? = nil,
        notes: String? = nil,
        icon: String? = nil,
        iconColor: String? = nil,
        isCurrent: Bool = false,
        createdAt: Date = Date(),
        sortIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.settingsConfig = settingsConfig
        self.category = category
        self.websiteUrl = websiteUrl
        self.notes = notes
        self.icon = icon
        self.iconColor = iconColor
        self.isCurrent = isCurrent
        self.createdAt = createdAt
        self.sortIndex = sortIndex
    }

    /// API Key（优先 ANTHROPIC_AUTH_TOKEN，备选 ANTHROPIC_API_KEY）
    var apiKey: String? {
        settingsConfig["ANTHROPIC_AUTH_TOKEN"] ?? settingsConfig["ANTHROPIC_API_KEY"]
    }

    /// Base URL
    var baseUrl: String? {
        settingsConfig["ANTHROPIC_BASE_URL"]
    }

    /// 主模型
    var model: String? {
        settingsConfig["ANTHROPIC_MODEL"]
    }

    static func == (lhs: ClaudeProvider, rhs: ClaudeProvider) -> Bool {
        lhs.id == rhs.id
    }
}
