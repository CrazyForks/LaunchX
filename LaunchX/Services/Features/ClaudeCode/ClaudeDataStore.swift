import Foundation

/// Claude Code 数据存储管理器
/// 负责读写 JSON 配置文件，支持原子写入
final class ClaudeDataStore {
    static let shared = ClaudeDataStore()

    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.launchx.clauddatastore", qos: .userInitiated)

    // MARK: - 目录路径

    /// Claude Code 数据根目录
    let claudeDir: URL

    /// 备份目录
    let backupsDir: URL

    /// Skills 主副本目录
    let skillsDir: URL

    // MARK: - 文件路径

    private var providersFile: URL { claudeDir.appendingPathComponent("providers.json") }
    private var mcpServersFile: URL { claudeDir.appendingPathComponent("mcp_servers.json") }
    private var skillsFile: URL { claudeDir.appendingPathComponent("skills.json") }
    private var skillReposFile: URL { claudeDir.appendingPathComponent("skill_repos.json") }

    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        claudeDir = appSupport.appendingPathComponent("LaunchX/claude", isDirectory: true)
        backupsDir = claudeDir.appendingPathComponent("backups", isDirectory: true)
        skillsDir = claudeDir.appendingPathComponent("skills", isDirectory: true)
        initializeDirectories()
    }

    // MARK: - 目录初始化

    private func initializeDirectories() {
        try? fileManager.createDirectory(at: claudeDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: backupsDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: skillsDir, withIntermediateDirectories: true)
    }

    // MARK: - 通用读写

    /// 原子写入 JSON 文件
    func writeJSON<T: Encodable>(_ data: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(data)

        // 原子写入：先写临时文件，再替换目标文件
        let tempURL = url.deletingLastPathComponent()
            .appendingPathComponent(".tmp_\(UUID().uuidString)")
        // 不用 .atomic，直接写入临时文件（避免 .atomic 内部 rename 与后续 moveItem 冲突）
        try jsonData.write(to: tempURL, options: [])
        // 原子替换：如果目标已存在先删除，再将临时文件移动过去
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        try fileManager.moveItem(at: tempURL, to: url)
    }

    /// 读取 JSON 文件
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

    func loadProviders() -> [ClaudeProvider] {
        queue.sync {
            readJSON([ClaudeProvider].self, from: providersFile) ?? []
        }
    }

    func saveProviders(_ providers: [ClaudeProvider]) throws {
        try queue.sync {
            try writeJSON(providers, to: providersFile)
        }
    }

    // MARK: - MCP Server 操作

    func loadMcpServers() -> [McpServer] {
        queue.sync {
            readJSON([McpServer].self, from: mcpServersFile) ?? []
        }
    }

    func saveMcpServers(_ servers: [McpServer]) throws {
        try queue.sync {
            try writeJSON(servers, to: mcpServersFile)
        }
    }

    // MARK: - Skills 操作

    func loadSkills() -> [ClaudeSkill] {
        queue.sync {
            readJSON([ClaudeSkill].self, from: skillsFile) ?? []
        }
    }

    func saveSkills(_ skills: [ClaudeSkill]) throws {
        try queue.sync {
            try writeJSON(skills, to: skillsFile)
        }
    }

    // MARK: - Skill Repos 操作

    func loadSkillRepos() -> [SkillRepo] {
        queue.sync {
            readJSON([SkillRepo].self, from: skillReposFile) ?? SkillRepo.defaults
        }
    }

    func saveSkillRepos(_ repos: [SkillRepo]) throws {
        try queue.sync {
            try writeJSON(repos, to: skillReposFile)
        }
    }

    // MARK: - 备份操作

    /// 备份 Claude Code 的 settings.json
    func backupClaudeSettings() throws {
        let claudeSettingsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
        guard fileManager.fileExists(atPath: claudeSettingsPath.path) else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let backupFile = backupsDir.appendingPathComponent("settings_\(timestamp).json")

        try? fileManager.copyItem(at: claudeSettingsPath, to: backupFile)
        cleanupOldBackups()
    }

    /// 清理旧备份，保留最近 10 个
    private func cleanupOldBackups() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: backupsDir, includingPropertiesForKeys: [.creationDateKey])
            .filter({ $0.path.contains("settings_") })
            .sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
        else { return }

        if files.count > 10 {
            for file in files.dropFirst(10) {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    /// 获取备份列表
    func listBackups() -> [URL] {
        (try? fileManager.contentsOfDirectory(
            at: backupsDir, includingPropertiesForKeys: nil)
            .filter { $0.path.contains("settings_") }
            .sorted(by: { $0.lastPathComponent > $1.lastPathComponent })) ?? []
    }
}
