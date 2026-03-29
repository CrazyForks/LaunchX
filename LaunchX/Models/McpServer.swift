import Foundation

/// MCP 服务器类型
enum McpServerType: String, CaseIterable {
    case stdio
    case http
    case sse

    var displayName: String {
        switch self {
        case .stdio: return "stdio"
        case .http: return "HTTP"
        case .sse: return "SSE"
        }
    }
}

/// Claude Code MCP 服务器数据模型
struct McpServer: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var serverConfig: [String: AnyCodable]
    var serverDescription: String?
    var homepage: String?
    var docs: String?
    var tags: [String]
    var isEnabled: Bool

    var serverType: McpServerType {
        if serverConfig["url"] != nil {
            return .sse
        }
        return .stdio
    }

    var configSummary: String {
        switch serverType {
        case .stdio:
            let command = serverConfig["command"]?.stringValue ?? ""
            let args = (serverConfig["args"]?.arrayValue ?? []).compactMap { $0.stringValue }.joined(separator: " ")
            return args.isEmpty ? command : command
        case .http, .sse:
            return serverConfig["url"]?.stringValue ?? ""
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        serverConfig: [String: AnyCodable] = [:],
        serverDescription: String? = nil,
        homepage: String? = nil,
        docs: String? = nil,
        tags: [String] = [],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.serverConfig = serverConfig
        self.serverDescription = serverDescription
        self.homepage = homepage
        self.docs = docs
        self.tags = tags
        self.isEnabled = isEnabled
    }

    static func == (lhs: McpServer, rhs: McpServer) -> Bool {
        lhs.id == rhs.id
    }
}

