import Foundation

/// Codex CLI Provider 预设模板
struct CodexProviderPreset: Identifiable, Codable {
    let id: String
    let name: String
    let providerId: String
    let baseUrl: String?
    let envKey: String?
    let wireApi: String?
    let queryParams: [String: String]?
    let model: String?
    let category: CodexProviderCategory
    let icon: String?
    let iconColor: String?
    let presetDescription: String?
    let websiteUrl: String?
    let notes: String?

    init(
        id: String,
        name: String,
        providerId: String,
        baseUrl: String? = nil,
        envKey: String? = nil,
        wireApi: String? = nil,
        queryParams: [String: String]? = nil,
        model: String? = nil,
        category: CodexProviderCategory,
        icon: String? = nil,
        iconColor: String? = nil,
        presetDescription: String? = nil,
        websiteUrl: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.providerId = providerId
        self.baseUrl = baseUrl
        self.envKey = envKey
        self.wireApi = wireApi
        self.queryParams = queryParams
        self.model = model
        self.category = category
        self.icon = icon
        self.iconColor = iconColor
        self.presetDescription = presetDescription
        self.websiteUrl = websiteUrl
        self.notes = notes
    }

    /// 从预设创建 Provider 实例
    func createProvider(apiKey: String) -> CodexProvider {
        CodexProvider(
            name: name,
            providerId: providerId,
            baseUrl: baseUrl ?? "",
            envKey: envKey ?? "OPENAI_API_KEY",
            apiKey: apiKey,
            wireApi: wireApi,
            queryParams: queryParams,
            model: model,
            category: category,
            notes: notes,
            icon: icon,
            iconColor: iconColor
        )
    }
}

/// Codex CLI Provider 预设加载器
struct CodexProviderPresetLoader {
    static let builtInPresets: [CodexProviderPreset] = [
        // MARK: - 官方
        CodexProviderPreset(
            id: "openai", name: "OpenAI 官方", providerId: "openai",
            baseUrl: "https://api.openai.com/v1", envKey: "OPENAI_API_KEY",
            wireApi: "responses", model: "o4-mini",
            category: .official, icon: "brain", iconColor: "#10A37F",
            presetDescription: "OpenAI 官方 API", websiteUrl: "https://platform.openai.com"
        ),
        // MARK: - 国内官方/代理
        CodexProviderPreset(
            id: "openai-cn", name: "OpenAI 国内代理", providerId: "openai-cn",
            baseUrl: "https://api.openai-proxy.com/v1", envKey: "OPENAI_API_KEY",
            wireApi: "responses", model: "o4-mini",
            category: .cnOfficial, icon: "brain", iconColor: "#10A37F",
            presetDescription: "OpenAI 国内代理站点"
        ),
        CodexProviderPreset(
            id: "api2d", name: "API2D", providerId: "api2d",
            baseUrl: "https://oa.api2d.net/v1", envKey: "API2D_KEY",
            wireApi: "responses", model: "o4-mini",
            category: .cnOfficial, icon: "bolt.fill", iconColor: "#FF6B35",
            presetDescription: "API2D 中转", websiteUrl: "https://api2d.com"
        ),
        CodexProviderPreset(
            id: "openai-sb", name: "OpenAI-SB", providerId: "openai-sb",
            baseUrl: "https://api.openai-sb.com/v1", envKey: "OPENAI_SB_API_KEY",
            wireApi: "responses", model: "o4-mini",
            category: .cnOfficial, icon: "bolt.fill", iconColor: "#9B59B6",
            presetDescription: "OpenAI-SB 中转"
        ),
        CodexProviderPreset(
            id: "closeai", name: "CloseAI", providerId: "closeai",
            baseUrl: "https://api.closeai-proxy.xyz/v1", envKey: "CLOSEAI_API_KEY",
            wireApi: "responses", model: "o4-mini",
            category: .cnOfficial, icon: "bolt.fill", iconColor: "#E74C3C",
            presetDescription: "CloseAI 代理"
        ),
        // MARK: - 聚合器
        CodexProviderPreset(
            id: "openrouter", name: "OpenRouter", providerId: "openrouter",
            baseUrl: "https://openrouter.ai/api/v1", envKey: "OPENROUTER_API_KEY",
            wireApi: "chat_completions", model: "openai/o4-mini",
            category: .aggregator, icon: "arrow.triangle.branch", iconColor: "#6D28D9",
            presetDescription: "OpenRouter 多模型聚合", websiteUrl: "https://openrouter.ai"
        ),
        CodexProviderPreset(
            id: "together", name: "Together AI", providerId: "together",
            baseUrl: "https://api.together.xyz/v1", envKey: "TOGETHER_API_KEY",
            wireApi: "chat_completions", model: "openai/o4-mini",
            category: .aggregator, icon: "person.2.fill", iconColor: "#3B82F6",
            presetDescription: "Together AI 推理平台", websiteUrl: "https://together.ai"
        ),
        CodexProviderPreset(
            id: "groq", name: "Groq", providerId: "groq",
            baseUrl: "https://api.groq.com/openai/v1", envKey: "GROQ_API_KEY",
            wireApi: "chat_completions", model: "llama-3.3-70b-versatile",
            category: .aggregator, icon: "bolt.horizontal.fill", iconColor: "#F55036",
            presetDescription: "Groq 高速推理", websiteUrl: "https://groq.com"
        ),
        CodexProviderPreset(
            id: "deepinfra", name: "DeepInfra", providerId: "deepinfra",
            baseUrl: "https://api.deepinfra.com/v1/openai", envKey: "DEEPINFRA_API_KEY",
            wireApi: "chat_completions", model: "meta-llama/Meta-Llama-3.1-70B-Instruct",
            category: .aggregator, icon: "server.rack", iconColor: "#7C3AED",
            presetDescription: "DeepInfra 推理平台", websiteUrl: "https://deepinfra.com"
        ),
        CodexProviderPreset(
            id: "siliconflow", name: "SiliconFlow", providerId: "siliconflow",
            baseUrl: "https://api.siliconflow.cn/v1", envKey: "SILICONFLOW_API_KEY",
            wireApi: "chat_completions", model: "deepseek-ai/DeepSeek-V3",
            category: .aggregator, icon: "cpu", iconColor: "#8B5CF6",
            presetDescription: "硅基流动", websiteUrl: "https://siliconflow.cn"
        ),
        // MARK: - 第三方
        CodexProviderPreset(
            id: "mistral", name: "Mistral AI", providerId: "mistral",
            baseUrl: "https://api.mistral.ai/v1", envKey: "MISTRAL_API_KEY",
            wireApi: "chat_completions", model: "mistral-large-latest",
            category: .thirdParty, icon: "wind", iconColor: "#FF7000",
            presetDescription: "Mistral AI", websiteUrl: "https://mistral.ai"
        ),
        CodexProviderPreset(
            id: "deepseek", name: "DeepSeek", providerId: "deepseek",
            baseUrl: "https://api.deepseek.com/v1", envKey: "DEEPSEEK_API_KEY",
            wireApi: "chat_completions", model: "deepseek-chat",
            category: .thirdParty, icon: "magnifyingglass", iconColor: "#4D6BFE",
            presetDescription: "DeepSeek", websiteUrl: "https://deepseek.com"
        ),
        CodexProviderPreset(
            id: "anthropic-via-openai", name: "Anthropic (兼容接口)", providerId: "anthropic-compat",
            baseUrl: "https://api.anthropic.com/v1", envKey: "ANTHROPIC_API_KEY",
            wireApi: "chat_completions", model: "claude-sonnet-4-6-20250514",
            category: .thirdParty, icon: "brain.head.profile", iconColor: "#D97706",
            presetDescription: "Anthropic Claude (通过 OpenAI 兼容接口)"
        ),
        CodexProviderPreset(
            id: "xai", name: "xAI (Grok)", providerId: "xai",
            baseUrl: "https://api.x.ai/v1", envKey: "XAI_API_KEY",
            wireApi: "chat_completions", model: "grok-3",
            category: .thirdParty, icon: "sparkles", iconColor: "#000000",
            presetDescription: "xAI Grok", websiteUrl: "https://x.ai"
        ),
        // MARK: - 云提供商
        CodexProviderPreset(
            id: "azure", name: "Azure OpenAI", providerId: "azure",
            baseUrl: "", envKey: "AZURE_OPENAI_API_KEY",
            wireApi: "responses",
            queryParams: ["api-version": "2025-04-01-preview"],
            model: "gpt-4.1",
            category: .cloudProvider, icon: "cloud.fill", iconColor: "#0078D4",
            presetDescription: "Azure OpenAI Service", websiteUrl: "https://azure.microsoft.com/en-us/products/ai-services/openai-service",
            notes: "需要填写你的 Azure OpenAI 端点 URL"
        ),
        CodexProviderPreset(
            id: "amazon-bedrock", name: "Amazon Bedrock", providerId: "amazon-bedrock",
            baseUrl: "", envKey: "",
            model: "us.anthropic.claude-sonnet-4-20250514",
            category: .cloudProvider, icon: "cloud.fill", iconColor: "#FF9900",
            presetDescription: "Amazon Bedrock", websiteUrl: "https://aws.amazon.com/bedrock",
            notes: "使用 AWS 凭证认证，需要配置 AWS CLI"
        ),
        CodexProviderPreset(
            id: "google-vertex", name: "Google Vertex AI", providerId: "vertex",
            baseUrl: "", envKey: "GOOGLE_API_KEY",
            wireApi: "chat_completions", model: "gemini-2.5-pro",
            category: .cloudProvider, icon: "cloud.fill", iconColor: "#4285F4",
            presetDescription: "Google Vertex AI"
        ),
        // MARK: - 本地模型
        CodexProviderPreset(
            id: "ollama", name: "Ollama", providerId: "ollama",
            baseUrl: "http://localhost:11434/v1", envKey: "OLLAMA_API_KEY",
            wireApi: "chat_completions", model: "qwen3:32b",
            category: .local, icon: "desktopcomputer", iconColor: "#6366F1",
            presetDescription: "Ollama 本地模型", websiteUrl: "https://ollama.ai",
            notes: "需要先启动 Ollama 服务"
        ),
        CodexProviderPreset(
            id: "lmstudio", name: "LM Studio", providerId: "lmstudio",
            baseUrl: "http://localhost:1234/v1", envKey: "LMSTUDIO_API_KEY",
            wireApi: "chat_completions", model: "default",
            category: .local, icon: "laptopcomputer.and.arrow.down", iconColor: "#059669",
            presetDescription: "LM Studio 本地模型", websiteUrl: "https://lmstudio.ai",
            notes: "需要先启动 LM Studio 服务"
        ),
        CodexProviderPreset(
            id: "localai", name: "LocalAI", providerId: "localai",
            baseUrl: "http://localhost:8080/v1", envKey: "LOCALAI_API_KEY",
            wireApi: "chat_completions", model: "gpt-4",
            category: .local, icon: "internaldrive", iconColor: "#DC2626",
            presetDescription: "LocalAI 本地推理", websiteUrl: "https://localai.io"
        ),
    ]

    static var groupedPresets: [(category: CodexProviderCategory, presets: [CodexProviderPreset])] {
        let categories = CodexProviderCategory.allCases
        return categories.compactMap { cat in
            let presets = builtInPresets.filter { $0.category == cat }
            return presets.isEmpty ? nil : (cat, presets)
        }
    }
}
