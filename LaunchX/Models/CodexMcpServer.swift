import Foundation

/// Codex MCP Server 传输类型
enum CodexMcpServerType: String, Codable, CaseIterable {
    case stdio
    case streamableHttp = "streamable_http"

    var displayName: String {
        switch self {
        case .stdio: return "STDIO"
        case .streamableHttp: return "Streamable HTTP"
        }
    }
}

/// Codex CLI MCP Server 配置模型
struct CodexMcpServer: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var serverType: CodexMcpServerType
    var command: String?           // STDIO 启动命令
    var args: [String]?            // 命令参数
    var url: String?               // HTTP 端点
    var env: [String: String]?     // 传递给服务器的环境变量
    var isEnabled: Bool
    var startupTimeoutSec: Int?    // 启动超时（默认 10）
    var toolTimeoutSec: Int?       // 工具超时（默认 60）
    var enabledTools: [String]?    // 工具白名单
    var disabledTools: [String]?   // 工具黑名单
    var bearerTokenEnvVar: String? // HTTP 认证 token 环境变量
    var httpHeaders: [String: String]? // 静态 HTTP 头
    var required: Bool?            // 启动失败是否报错
    var serverDescription: String?
    var homepage: String?
    var docs: String?
    var tags: [String]

    init(
        id: UUID = UUID(),
        name: String,
        serverType: CodexMcpServerType = .stdio,
        command: String? = nil,
        args: [String]? = nil,
        url: String? = nil,
        env: [String: String]? = nil,
        isEnabled: Bool = true,
        startupTimeoutSec: Int? = nil,
        toolTimeoutSec: Int? = nil,
        enabledTools: [String]? = nil,
        disabledTools: [String]? = nil,
        bearerTokenEnvVar: String? = nil,
        httpHeaders: [String: String]? = nil,
        required: Bool? = nil,
        serverDescription: String? = nil,
        homepage: String? = nil,
        docs: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.serverType = serverType
        self.command = command
        self.args = args
        self.url = url
        self.env = env
        self.isEnabled = isEnabled
        self.startupTimeoutSec = startupTimeoutSec
        self.toolTimeoutSec = toolTimeoutSec
        self.enabledTools = enabledTools
        self.disabledTools = disabledTools
        self.bearerTokenEnvVar = bearerTokenEnvVar
        self.httpHeaders = httpHeaders
        self.required = required
        self.serverDescription = serverDescription
        self.homepage = homepage
        self.docs = docs
        self.tags = tags
    }

    /// 配置摘要（用于搜索面板显示）
    var configSummary: String {
        switch serverType {
        case .stdio:
            let cmd = command ?? ""
            let argStr = (args ?? []).joined(separator: " ")
            return argStr.isEmpty ? cmd : "\(cmd) \(argStr)"
        case .streamableHttp:
            return url ?? ""
        }
    }
}
