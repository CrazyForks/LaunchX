import Foundation

/// Claude Code Skill 数据模型
struct ClaudeSkill: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var skillDescription: String?
    var directory: String
    var repoOwner: String
    var repoName: String
    var repoBranch: String
    var readmeUrl: String?
    var isEnabled: Bool
    var installedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        skillDescription: String? = nil,
        directory: String,
        repoOwner: String = "",
        repoName: String = "",
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

    /// 来源仓库全名
    var repoFullName: String {
        "\(repoOwner)/\(repoName)"
    }

    /// SKILL.md 内容的 GitHub Raw URL
    var skillRawUrl: String {
        "https://raw.githubusercontent.com/\(repoOwner)/\(repoName)/\(repoBranch)/\(directory)/SKILL.md"
    }

    static func == (lhs: ClaudeSkill, rhs: ClaudeSkill) -> Bool {
        lhs.id == rhs.id
    }
}
