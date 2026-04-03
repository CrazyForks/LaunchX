import Combine
import Foundation

/// Claude Code MCP 服务器管理服务
@MainActor
final class ClaudeMcpService: ObservableObject {
    static let shared = ClaudeMcpService()

    @Published var servers: [McpServer] = []

    private let store = ClaudeDataStore.shared
    private let fileManager = FileManager.default

    private init() {
        loadData()
    }

    // MARK: - 数据加载

    private func loadData() {
        servers = store.loadMcpServers()
    }

    private func persistData() throws {
        try store.saveMcpServers(servers)
    }

    // MARK: - Claude Code MCP 配置路径

    private var claudeJsonPath: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".claude.json")
    }

    // MARK: - 验证

    /// 验证 MCP 服务器配置
    func validateConfig(_ config: [String: AnyCodable]) -> String? {
        let typeStr = config["type"]?.stringValue ?? ""
        if typeStr == "http" || typeStr == "sse" {
            guard let url = config["url"]?.stringValue, !url.isEmpty else {
                return "HTTP/SSE 类型服务器必须包含 url 字段"
            }
            return nil
        }
        // stdio（默认）
        guard let command = config["command"]?.stringValue, !command.isEmpty else {
            return "stdio 类型服务器必须包含 command 字段"
        }
        return nil
    }

    // MARK: - CRUD

    /// 添加 MCP
    @discardableResult
    func addServer(_ server: McpServer) throws -> String? {
        if let error = validateConfig(server.serverConfig) {
            return error
        }
        servers.append(server)
        try persistData()
        if server.isEnabled {
            try syncToClaude()
        }
        return nil
    }

    /// 更新 MCP
    func updateServer(_ server: McpServer) throws {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }
        servers[index] = server
        try persistData()
        if server.isEnabled {
            try syncToClaude()
        }
    }

    /// 删除 MCP
    func deleteServer(_ server: McpServer) throws {
        servers.removeAll { $0.id == server.id }
        try persistData()
        try syncToClaude()
    }

    // MARK: - 启用/禁用

    /// 切换 MCP 服务器启用状态
    func toggleEnabled(_ server: McpServer) throws {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }
        servers[index].isEnabled.toggle()
        try persistData()
        try syncToClaude()
    }

    // MARK: - 同步到 Claude Code

    /// 读取 ~/.claude.json
    func readClaudeJson() -> [String: Any]? {
        guard fileManager.fileExists(atPath: claudeJsonPath.path),
            let data = try? Data(contentsOf: claudeJsonPath),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return json
    }

    /// 将所有启用的 MCP 服务器同步到 ~/.claude.json
    func syncToClaude() throws {
        var config = readClaudeJson() ?? [:]

        // 构建启用的 MCP 服务器配置
        var mcpServers: [String: Any] = [:]
        for server in servers where server.isEnabled {
            // 将 [String: AnyCodable] 转为 [String: Any]
            var serverConfig: [String: Any] = [:]
            for (key, value) in server.serverConfig {
                serverConfig[key] = value.value
            }
            mcpServers[server.name] = serverConfig
        }

        config["mcpServers"] = mcpServers

        let jsonData = try JSONSerialization.data(
            withJSONObject: config, options: [.prettyPrinted, .sortedKeys])

        // 原子写入
        let tempPath = claudeJsonPath.deletingLastPathComponent()
            .appendingPathComponent(".tmp_claude_json_\(UUID().uuidString)")
        do {
            // 确保目录存在
            let dir = claudeJsonPath.deletingLastPathComponent()
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)

            try jsonData.write(to: tempPath, options: [])
            if fileManager.fileExists(atPath: claudeJsonPath.path) {
                _ = try? fileManager.replaceItemAt(claudeJsonPath, withItemAt: tempPath)
            } else {
                try fileManager.moveItem(at: tempPath, to: claudeJsonPath)
            }
        } catch {
            try? fileManager.removeItem(at: tempPath)
            throw error
        }
    }

    // MARK: - 导入

    /// 从 ~/.claude.json 导入 MCP
    func importFromClaude() -> Int {
        guard let config = readClaudeJson(),
            let mcpServers = config["mcpServers"] as? [String: Any]
        else {
            return 0
        }

        var imported = 0
        for (name, serverConfig) in mcpServers {
            // 跳过已存在的
            if servers.contains(where: { $0.name == name }) { continue }

            // 转换为 [String: AnyCodable]
            var config: [String: AnyCodable] = [:]
            if let dict = serverConfig as? [String: Any] {
                for (key, value) in dict {
                    config[key] = AnyCodable(value)
                }
            }

            // 验证
            if validateConfig(config) != nil { continue }

            let server = McpServer(
                name: name,
                serverConfig: config,
                isEnabled: true
            )
            servers.append(server)
            imported += 1
        }

        if imported > 0 {
            try? persistData()
        }
        return imported
    }
}
