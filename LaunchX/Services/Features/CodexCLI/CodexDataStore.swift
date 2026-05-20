import Foundation

/// Codex CLI 数据存储管理器
/// 负责读写 JSON 配置文件，支持原子写入
final class CodexDataStore {
    static let shared = CodexDataStore()

    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.launchx.codexdatastore", qos: .userInitiated)

    // MARK: - 目录路径

    let codexDir: URL
    let backupsDir: URL
    let skillsDir: URL

    // MARK: - 文件路径

    private var providersFile: URL { codexDir.appendingPathComponent("providers.json") }
    private var mcpServersFile: URL { codexDir.appendingPathComponent("mcp_servers.json") }
    private var skillsFile: URL { codexDir.appendingPathComponent("skills.json") }
    private var skillReposFile: URL { codexDir.appendingPathComponent("skill_repos.json") }

    /// Codex CLI config.toml 路径
    var codexConfigPath: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/config.toml")
    }

    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        codexDir = appSupport.appendingPathComponent("LaunchX/codex", isDirectory: true)
        backupsDir = codexDir.appendingPathComponent("backups", isDirectory: true)
        skillsDir = codexDir.appendingPathComponent("skills", isDirectory: true)
        initializeDirectories()
    }

    private func initializeDirectories() {
        try? fileManager.createDirectory(at: codexDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: backupsDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: skillsDir, withIntermediateDirectories: true)
    }

    // MARK: - 通用读写

    func writeJSON<T: Encodable>(_ data: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(data)

        let tempURL = url.deletingLastPathComponent()
            .appendingPathComponent(".tmp_\(UUID().uuidString)")
        try jsonData.write(to: tempURL, options: [])
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        try fileManager.moveItem(at: tempURL, to: url)
    }

    func readJSON<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }

    // MARK: - Provider 操作

    func loadProviders() -> [CodexProvider] {
        queue.sync {
            readJSON([CodexProvider].self, from: providersFile) ?? []
        }
    }

    func saveProviders(_ providers: [CodexProvider]) throws {
        try queue.sync {
            try writeJSON(providers, to: providersFile)
        }
    }

    // MARK: - MCP Server 操作

    func loadMcpServers() -> [CodexMcpServer] {
        queue.sync {
            readJSON([CodexMcpServer].self, from: mcpServersFile) ?? []
        }
    }

    func saveMcpServers(_ servers: [CodexMcpServer]) throws {
        try queue.sync {
            try writeJSON(servers, to: mcpServersFile)
        }
    }

    // MARK: - Skills 操作

    func loadSkills() -> [CodexSkill] {
        queue.sync {
            readJSON([CodexSkill].self, from: skillsFile) ?? []
        }
    }

    func saveSkills(_ skills: [CodexSkill]) throws {
        try queue.sync {
            try writeJSON(skills, to: skillsFile)
        }
    }

    // MARK: - Skill Repos 操作

    func loadSkillRepos() -> [CodexSkillRepo] {
        queue.sync {
            readJSON([CodexSkillRepo].self, from: skillReposFile) ?? []
        }
    }

    func saveSkillRepos(_ repos: [CodexSkillRepo]) throws {
        try queue.sync {
            try writeJSON(repos, to: skillReposFile)
        }
    }

    // MARK: - config.toml 备份

    func backupCodexConfig() throws {
        guard fileManager.fileExists(atPath: codexConfigPath.path) else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let backupFile = backupsDir.appendingPathComponent("config_\(timestamp).toml")

        try? fileManager.copyItem(at: codexConfigPath, to: backupFile)
        cleanupOldBackups()
    }

    private func cleanupOldBackups() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: backupsDir, includingPropertiesForKeys: [.creationDateKey])
            .filter({ $0.path.contains("config_") })
            .sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
        else { return }

        if files.count > 10 {
            for file in files.dropFirst(10) {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    func listBackups() -> [URL] {
        (try? fileManager.contentsOfDirectory(
            at: backupsDir, includingPropertiesForKeys: nil)
            .filter { $0.path.contains("config_") }
            .sorted(by: { $0.lastPathComponent > $1.lastPathComponent })) ?? []
    }

    // MARK: - config.toml 读写

    /// 读取 config.toml 内容
    func readCodexConfig() -> String? {
        guard fileManager.fileExists(atPath: codexConfigPath.path) else { return nil }
        return try? String(contentsOf: codexConfigPath, encoding: .utf8)
    }

    /// 原子写入 config.toml
    func writeCodexConfig(_ content: String) throws {
        let tempURL = codexConfigPath.deletingLastPathComponent()
            .appendingPathComponent(".tmp_\(UUID().uuidString)")
        try content.write(to: tempURL, atomically: false, encoding: .utf8)
        if fileManager.fileExists(atPath: codexConfigPath.path) {
            try fileManager.removeItem(at: codexConfigPath)
        }
        try fileManager.moveItem(at: tempURL, to: codexConfigPath)
    }
}
