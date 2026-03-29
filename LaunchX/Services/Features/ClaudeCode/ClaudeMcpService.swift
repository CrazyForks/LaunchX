import Foundation
import Combine

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

    private func persistData() {
        try? store.saveMcpServers(servers)
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

    /// 添加 MCP 服务器
    @discardableResult
    func addServer(_ server: McpServer) -> String? {
        if let error = validateConfig(server.serverConfig) {
            return error
        }
        servers.append(server)
        persistData()
        if server.isEnabled {
            syncToClaude()
        }
        return nil
    }

    /// 更新 MCP 服务器
    func updateServer(_ server: McpServer) {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }
        servers[index] = server
        persistData()
        if server.isEnabled {
            syncToClaude()
        }
    }

    /// 删除 MCP 服务器
    func deleteServer(_ server: McpServer) {
        servers.removeAll { $0.id == server.id }
        persistData()
        syncToClaude()
    }

    // MARK: - 启用/禁用

    /// 切换 MCP 服务器启用状态
    func toggleEnabled(_ server: McpServer) {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }
        servers[index].isEnabled.toggle()
        persistData()
        syncToClaude()
    }

    // MARK: - 同步到 Claude Code

    /// 读取 ~/.claude.json
    func readClaudeJson() -> [String: Any]? {
        guard fileManager.fileExists(atPath: claudeJsonPath.path),
              let data = try? Data(contentsOf: claudeJsonPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }

    /// 将所有启用的 MCP 服务器同步到 ~/.claude.json
    func syncToClaude() {
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

        guard let jsonData = try? JSONSerialization.data(
            withJSONObject: config, options: [.prettyPrinted, .sortedKeys]) else {
            return
        }

        // 原子写入
        let tempPath = claudeJsonPath.deletingLastPathComponent()
            .appendingPathComponent(".tmp_claude_json_\(UUID().uuidString)")
        do {
            // 确保目录存在
            let dir = claudeJsonPath.deletingLastPathComponent()
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)

            try jsonData.write(to: tempPath, options: .atomic)
            if fileManager.fileExists(atPath: claudeJsonPath.path) {
                try fileManager.removeItem(at: claudeJsonPath)
            }
            try fileManager.moveItem(at: tempPath, to: claudeJsonPath)
        } catch {
            try? fileManager.removeItem(at: tempPath)
        }
    }

    // MARK: - 导入

    /// 从 ~/.claude.json 导入 MCP 服务器
    func importFromClaude() -> Int {
        guard let config = readClaudeJson(),
              let mcpServers = config["mcpServers"] as? [String: Any] else {
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
            persistData()
        }
        return imported
    }
}
