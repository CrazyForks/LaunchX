import Foundation

/// Codex CLI Skill 配置模型
struct CodexSkill: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var skillDescription: String?
    var directory: String          // 本地存储目录名
    var repoOwner: String
    var repoName: String
    var repoBranch: String         // 默认 "main"
    var readmeUrl: String?
    var isEnabled: Bool
    var installedAt: Date

    var repoFullName: String { "\(repoOwner)/\(repoName)" }

    /// SKILL.md 的 GitHub Raw URL
    var skillRawUrl: String {
        guard let readmeUrl = readmeUrl else {
            return "https://raw.githubusercontent.com/\(repoOwner)/\(repoName)/\(repoBranch)/\(directory)/SKILL.md"
        }
        return readmeUrl
    }

    init(
        id: UUID = UUID(),
        name: String,
        skillDescription: String? = nil,
        directory: String,
        repoOwner: String,
        repoName: String,
        repoBranch: String = "main",
        readmeUrl: String? = nil,
        isEnabled: Bool = true,
        installedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.skillDescription = skillDescription
        self.directory = directory
        self.repoOwner = repoOwner
        self.repoName = repoName
        self.repoBranch = repoBranch
        self.readmeUrl = readmeUrl
        self.isEnabled = isEnabled
        self.installedAt = installedAt
    }
}

/// Codex Skill 来源仓库
struct CodexSkillRepo: Identifiable, Codable, Equatable {
    var id: UUID
    var owner: String
    var name: String
    var branch: String
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        owner: String,
        name: String,
        branch: String = "main",
        isEnabled: Bool = true
    ) {
        self.id = id
        self.owner = owner
        self.name = name
        self.branch = branch
        self.isEnabled = isEnabled
    }

    var fullName: String { "\(owner)/\(name)" }
}

/// 从 GitHub 发现的 Skill
struct CodexDiscoveredSkill: Identifiable {
    let id = UUID()
    let name: String
    let description: String?
    let directory: String
    let repoOwner: String
    let repoName: String
    let repoBranch: String
    let readmeUrl: String
}
