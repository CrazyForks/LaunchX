import Foundation
import Combine

/// Codex CLI MCP 服务器管理服务
@MainActor
final class CodexMcpService: ObservableObject {
    static let shared = CodexMcpService()

    @Published var servers: [CodexMcpServer] = []

    private let store = CodexDataStore.shared
    private let tomlParser = CodexTomlParser()

    private init() {
        loadData()
    }

    private func loadData() {
        servers = store.loadMcpServers()
    }

    private func persistData() throws {
        try store.saveMcpServers(servers)
    }

    // MARK: - 验证

    func validateConfig(_ server: CodexMcpServer) -> String? {
        switch server.serverType {
        case .stdio:
            guard let command = server.command, !command.isEmpty else {
                return "STDIO 类型服务器必须指定启动命令"
            }
            return nil
        case .streamableHttp:
            guard let url = server.url, !url.isEmpty else {
                return "HTTP 类型服务器必须指定服务器 URL"
            }
            return nil
        }
    }

    // MARK: - CRUD

    @discardableResult
    func addServer(_ server: CodexMcpServer) -> String? {
        if let error = validateConfig(server) {
            return error
        }
        servers.append(server)
        try? persistData()
        if server.isEnabled {
            try? syncToCodex()
        }
        return nil
    }

    func updateServer(_ server: CodexMcpServer) throws {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }
        servers[index] = server
        try persistData()
        if server.isEnabled {
            try syncToCodex()
        }
    }

    func deleteServer(_ server: CodexMcpServer) throws {
        servers.removeAll { $0.id == server.id }
        try persistData()
        try syncToCodex()
    }

    // MARK: - 启用/禁用

    func toggleEnabled(_ server: CodexMcpServer) throws {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }
        servers[index].isEnabled.toggle()
        try persistData()
        try syncToCodex()
    }

    // MARK: - 同步到 config.toml

    func syncToCodex() throws {
        var root: CodexTomlParser.TomlTable
        if let content = store.readCodexConfig() {
            root = tomlParser.parse(content)
        } else {
            root = CodexTomlParser.TomlTable()
        }

        // 重建 mcp_servers 段
        let mcpTable = CodexTomlParser.TomlTable()
        for server in servers {
            let serverEntry = CodexTomlParser.TomlTable()

            if !server.isEnabled {
                serverEntry["enabled"] = CodexTomlParser.TomlBool(false)
            }

            switch server.serverType {
            case .stdio:
                if let command = server.command {
                    serverEntry["command"] = CodexTomlParser.TomlString(command)
                }
                if let args = server.args, !args.isEmpty {
                    serverEntry["args"] = CodexTomlParser.TomlArray(args.map { CodexTomlParser.TomlString($0) })
                }
                if let env = server.env, !env.isEmpty {
                    let envTable = CodexTomlParser.TomlTable()
                    for (key, value) in env {
                        envTable[key] = CodexTomlParser.TomlString(value)
                    }
                    serverEntry["env"] = envTable
                }
            case .streamableHttp:
                if let url = server.url {
                    serverEntry["url"] = CodexTomlParser.TomlString(url)
                }
                if let bearerToken = server.bearerTokenEnvVar {
                    serverEntry["bearer_token_env_var"] = CodexTomlParser.TomlString(bearerToken)
                }
                if let headers = server.httpHeaders, !headers.isEmpty {
                    let headersTable = CodexTomlParser.TomlTable()
                    for (key, value) in headers {
                        headersTable[key] = CodexTomlParser.TomlString(value)
                    }
                    serverEntry["http_headers"] = headersTable
                }
            }

            // 通用字段
            if let timeout = server.startupTimeoutSec {
                serverEntry["startup_timeout_sec"] = CodexTomlParser.TomlInt(timeout)
            }
            if let timeout = server.toolTimeoutSec {
                serverEntry["tool_timeout_sec"] = CodexTomlParser.TomlInt(timeout)
            }
            if let enabledTools = server.enabledTools, !enabledTools.isEmpty {
                serverEntry["enabled_tools"] = CodexTomlParser.TomlArray(enabledTools.map { CodexTomlParser.TomlString($0) })
            }
            if let disabledTools = server.disabledTools, !disabledTools.isEmpty {
                serverEntry["disabled_tools"] = CodexTomlParser.TomlArray(disabledTools.map { CodexTomlParser.TomlString($0) })
            }
            if let required = server.required {
                serverEntry["required"] = CodexTomlParser.TomlBool(required)
            }

            mcpTable[server.name] = serverEntry
        }

        root["mcp_servers"] = mcpTable

        let content = tomlParser.serialize(root)
        try store.writeCodexConfig(content)
    }

    // MARK: - 导入

    func importFromCodex() -> Int {
        guard let content = store.readCodexConfig() else { return 0 }
        let root = tomlParser.parse(content)

        guard let mcpTable = root["mcp_servers"]?.tableValue else { return 0 }

        var imported = 0
        for (name, entry) in mcpTable.entries {
            if servers.contains(where: { $0.name == name }) { continue }
            guard let serverEntry = entry as? CodexTomlParser.TomlTable else { continue }

            let server = parseServerFromToml(name: name, table: serverEntry)
            if validateConfig(server) == nil {
                servers.append(server)
                imported += 1
            }
        }

        if imported > 0 {
            try? persistData()
        }
        return imported
    }

    private func parseServerFromToml(name: String, table: CodexTomlParser.TomlTable) -> CodexMcpServer {
        let hasUrl = table["url"]?.stringValue != nil
        let hasCommand = table["command"]?.stringValue != nil
        let serverType: CodexMcpServerType = hasUrl ? .streamableHttp : .stdio

        var env: [String: String]? = nil
        if let envTable = table["env"]?.tableValue {
            env = envTable.entries.compactMapValues { $0.stringValue }
        }

        var args: [String]? = nil
        if let arr = table["args"]?.arrayValue {
            args = arr.compactMap { $0.stringValue }
        }

        var enabledTools: [String]? = nil
        if let arr = table["enabled_tools"]?.arrayValue {
            enabledTools = arr.compactMap { $0.stringValue }
        }

        var disabledTools: [String]? = nil
        if let arr = table["disabled_tools"]?.arrayValue {
            disabledTools = arr.compactMap { $0.stringValue }
        }

        var httpHeaders: [String: String]? = nil
        if let hdrTable = table["http_headers"]?.tableValue {
            httpHeaders = hdrTable.entries.compactMapValues { $0.stringValue }
        }

        return CodexMcpServer(
            name: name,
            serverType: serverType,
            command: table["command"]?.stringValue,
            args: args,
            url: table["url"]?.stringValue,
            env: env,
            isEnabled: table["enabled"]?.boolValue ?? true,
            startupTimeoutSec: table["startup_timeout_sec"]?.intValue,
            toolTimeoutSec: table["tool_timeout_sec"]?.intValue,
            enabledTools: enabledTools,
            disabledTools: disabledTools,
            bearerTokenEnvVar: table["bearer_token_env_var"]?.stringValue,
            httpHeaders: httpHeaders,
            required: table["required"]?.boolValue
        )
    }
}
