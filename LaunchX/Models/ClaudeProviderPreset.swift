import Foundation

// MARK: - Provider 预设模型

/// Claude Code Provider 预设
struct ClaudeProviderPreset: Identifiable, Codable {
    let id: String
    var name: String
    var icon: String?
    var iconColor: String?
    var presetDescription: String?
    var category: ClaudeProviderCategory
    var env: [String: String]?
    var baseUrl: String?
    var model: String?
    var apiKeyField: String?  // ANTHROPIC_AUTH_TOKEN 或 ANTHROPIC_API_KEY
    var websiteUrl: String?
    var notes: String?

    /// 从预设创建 Provider
    func createProvider(apiKey: String) -> ClaudeProvider {
        var settingsConfig: [String: String] = [:]

        // 合并预设的 env
        if let presetEnv = env {
            settingsConfig.merge(presetEnv) { _, new in new }
        }

        // 设置 API Key
        let keyField = apiKeyField ?? "ANTHROPIC_AUTH_TOKEN"
        settingsConfig[keyField] = apiKey

        // 设置 Base URL
        if let baseUrl = baseUrl {
            settingsConfig["ANTHROPIC_BASE_URL"] = baseUrl
        }

        // 设置模型
        if let model = model {
            settingsConfig["ANTHROPIC_MODEL"] = model
        }

        return ClaudeProvider(
            name: name,
            settingsConfig: settingsConfig,
            category: category,
            websiteUrl: websiteUrl,
            notes: notes,
            icon: icon,
            iconColor: iconColor
        )
    }
}

// MARK: - 预设加载器

/// Provider 预设加载器
struct ClaudeProviderPresetLoader {
    /// 内置预设列表（不依赖外部 JSON 文件）
    static let builtInPresets: [ClaudeProviderPreset] = [
        // 官方
        ClaudeProviderPreset(
            id: "claude-official",
            name: "Claude Official",
            icon: "checkmark.shield",
            iconColor: "#D97706",
            presetDescription: "Anthropic 官方服务",
            category: .official,
            websiteUrl: "https://console.anthropic.com"
        ),
        // 聚合平台
        ClaudeProviderPreset(
            id: "openrouter",
            name: "OpenRouter",
            icon: "arrow.triangle.branch",
            iconColor: "#6366F1",
            presetDescription: "OpenRouter 聚合平台",
            category: .aggregator,
            baseUrl: "https://openrouter.ai/api/v1",
            model: "anthropic/claude-sonnet-4-5",
            apiKeyField: "ANTHROPIC_API_KEY",
            websiteUrl: "https://openrouter.ai"
        ),
        ClaudeProviderPreset(
            id: "siliconflow",
            name: "SiliconFlow",
            icon: "bolt.fill",
            iconColor: "#3B82F6",
            presetDescription: "SiliconFlow 聚合平台",
            category: .aggregator,
            baseUrl: "https://api.siliconflow.cn/v1",
            apiKeyField: "ANTHROPIC_API_KEY",
            websiteUrl: "https://siliconflow.cn"
        ),
        ClaudeProviderPreset(
            id: "dmxapi",
            name: "DMXAPI",
            icon: "link",
            iconColor: "#8B5CF6",
            presetDescription: "DMXAPI 全球模型 API",
            category: .aggregator,
            baseUrl: "https://www.dmxapi.com",
            websiteUrl: "https://www.dmxapi.com"
        ),
        ClaudeProviderPreset(
            id: "aihubmix",
            name: "AiHubMix",
            icon: "square.grid.2x2",
            iconColor: "#10B981",
            presetDescription: "AiHubMix 聚合平台",
            category: .aggregator,
            baseUrl: "https://aihubmix.com",
            websiteUrl: "https://aihubmix.com"
        ),
        ClaudeProviderPreset(
            id: "modelscope",
            name: "ModelScope",
            icon: "slider.horizontal.3",
            iconColor: "#F59E0B",
            presetDescription: "ModelScope 平台",
            category: .aggregator,
            baseUrl: "https://api-inference.modelscope.cn/v1",
            apiKeyField: "ANTHROPIC_API_KEY",
            websiteUrl: "https://modelscope.cn"
        ),
        // 第三方
        ClaudeProviderPreset(
            id: "packycode",
            name: "PackyCode",
            icon: "paperplane.fill",
            iconColor: "#EC4899",
            presetDescription: "PackyCode 中继服务",
            category: .thirdParty,
            websiteUrl: "https://packycode.com"
        ),
        ClaudeProviderPreset(
            id: "cubence",
            name: "Cubence",
            icon: "cube",
            iconColor: "#14B8A6",
            presetDescription: "Cubence API 中继",
            category: .thirdParty,
            websiteUrl: "https://cubence.com"
        ),
        ClaudeProviderPreset(
            id: "aigocode",
            name: "AIGoCode",
            icon: "chevron.left.forwardslash.chevron.right",
            iconColor: "#F97316",
            presetDescription: "AIGoCode 中继服务",
            category: .thirdParty,
            websiteUrl: "https://aigocode.com"
        ),
        ClaudeProviderPreset(
            id: "rightcode",
            name: "RightCode",
            icon: "arrow.right",
            iconColor: "#06B6D4",
            presetDescription: "RightCode 路由服务",
            category: .thirdParty,
            websiteUrl: "https://rightcode.io"
        ),
        ClaudeProviderPreset(
            id: "aicodemirror",
            name: "AICodeMirror",
            icon: "mirror",
            iconColor: "#84CC16",
            presetDescription: "AICodeMirror 中继服务",
            category: .thirdParty,
            websiteUrl: "https://aicodemirror.com"
        ),
        ClaudeProviderPreset(
            id: "sssaicode",
            name: "SSSAiCode",
            icon: "lock.shield",
            iconColor: "#64748B",
            presetDescription: "SSSAiCode 中继服务",
            category: .thirdParty,
            websiteUrl: "https://sssaicode.com"
        ),
        ClaudeProviderPreset(
            id: "micu",
            name: "Micu API",
            icon: "antenna.radiowaves.left.and.right",
            iconColor: "#A855F7",
            presetDescription: "Micu API 中继服务",
            category: .thirdParty,
            websiteUrl: "https://micuapi.com"
        ),
        // 云服务商
        ClaudeProviderPreset(
            id: "nvidia",
            name: "NVIDIA NIM",
            icon: "gpu",
            iconColor: "#76B900",
            presetDescription: "NVIDIA NIM 平台",
            category: .cloudProvider,
            baseUrl: "https://integrate.api.nvidia.com/v1",
            apiKeyField: "ANTHROPIC_API_KEY",
            websiteUrl: "https://build.nvidia.com"
        ),
        ClaudeProviderPreset(
            id: "alibaba-bailian",
            name: "百炼 (Alibaba)",
            icon: "cloud",
            iconColor: "#FF6A00",
            presetDescription: "阿里云百炼平台",
            category: .cloudProvider,
            baseUrl: "https://dashscope.aliyuncs.com/compatible-mode/v1",
            apiKeyField: "ANTHROPIC_API_KEY",
            websiteUrl: "https://bailian.console.aliyun.com"
        ),
        ClaudeProviderPreset(
            id: "volcengine-doubao",
            name: "火山引擎 (DouBao)",
            icon: "flame",
            iconColor: "#FF0000",
            presetDescription: "火山引擎豆包平台",
            category: .cloudProvider,
            baseUrl: "https://ark.cn-beijing.volces.com/api/v3",
            model: "doubao-seed-code-preview-latest",
            apiKeyField: "ANTHROPIC_API_KEY",
            websiteUrl: "https://console.volcengine.com/ark"
        ),
        // 更多第三方模型
        ClaudeProviderPreset(
            id: "deepseek",
            name: "DeepSeek",
            icon: "magnifyingglass",
            iconColor: "#4F46E5",
            presetDescription: "DeepSeek 模型服务",
            category: .thirdParty,
            baseUrl: "https://api.deepseek.com",
            model: "deepseek-chat",
            apiKeyField: "ANTHROPIC_API_KEY",
            websiteUrl: "https://platform.deepseek.com"
        ),
        ClaudeProviderPreset(
            id: "zhipu-glm",
            name: "智谱 GLM",
            icon: "textformat",
            iconColor: "#0EA5E9",
            presetDescription: "智谱 GLM 模型",
            category: .thirdParty,
            baseUrl: "https://open.bigmodel.cn/api/paas/v4",
            model: "glm-4-plus",
            apiKeyField: "ANTHROPIC_API_KEY",
            websiteUrl: "https://open.bigmodel.cn"
        ),
        ClaudeProviderPreset(
            id: "kimi",
            name: "Kimi",
            icon: "moon.stars",
            iconColor: "#7C3AED",
            presetDescription: "Kimi (Moonshot) 模型",
            category: .thirdParty,
            baseUrl: "https://api.moonshot.cn/v1",
            model: "moonshot-v1-auto",
            apiKeyField: "ANTHROPIC_API_KEY",
            websiteUrl: "https://platform.moonshot.cn"
        ),
        ClaudeProviderPreset(
            id: "minimax",
            name: "MiniMax",
            icon: "maximize",
            iconColor: "#DB2777",
            presetDescription: "MiniMax 模型服务",
            category: .thirdParty,
            baseUrl: "https://api.minimax.chat/v1",
            model: "MiniMax-M2.1",
            apiKeyField: "ANTHROPIC_API_KEY",
            websiteUrl: "https://platform.minimaxi.com"
        ),
        ClaudeProviderPreset(
            id: "xiaomi-mimo",
            name: "小米 MiMo",
            icon: "phone",
            iconColor: "#FF6900",
            presetDescription: "小米 MiMo 模型",
            category: .thirdParty,
            baseUrl: "https://api.maimemo.com/v1",
            model: "mimo-v2-flash",
            apiKeyField: "ANTHROPIC_API_KEY",
            websiteUrl: "https://aimi.xiaomi.com"
        ),
    ]

    /// 按 category 分组的预设
    static var groupedPresets: [(category: ClaudeProviderCategory, presets: [ClaudeProviderPreset])] {
        let grouped = Dictionary(grouping: builtInPresets) { $0.category }
        return ClaudeProviderCategory.allCases.compactMap { category in
            guard let presets = grouped[category], !presets.isEmpty else { return nil }
            return (category: category, presets: presets)
        }
    }
}
