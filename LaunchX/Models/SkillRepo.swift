import Foundation

/// Skill 仓库配置
struct SkillRepo: Identifiable, Codable, Equatable {
    let id: UUID
    var owner: String
    var name: String
    var branch: String
    var isEnabled: Bool

    var idString: String { "\(owner)/\(name)" }

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

    static func == (lhs: SkillRepo, rhs: SkillRepo) -> Bool {
        lhs.owner == rhs.owner && lhs.name == rhs.name
    }

    /// 默认仓库列表
    static let defaults: [SkillRepo] = [
        SkillRepo(owner: "anthropics", name: "skills"),
        SkillRepo(owner: "ComposioHQ", name: "awesome-claude-skills"),
    ]
}
