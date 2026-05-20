import Foundation
import Combine

/// Codex CLI Skills 管理服务
@MainActor
final class CodexSkillService: ObservableObject {
    static let shared = CodexSkillService()

    @Published var skills: [CodexSkill] = []
    @Published var repos: [CodexSkillRepo] = []
    @Published var discoveredSkills: [CodexDiscoveredSkill] = []
    @Published var isLoading = false

    private let store = CodexDataStore.shared
    private let fileManager = FileManager.default

    private init() {
        loadData()
    }

    // MARK: - 路径

    /// ~/.agents/skills/ 目标目录（Codex 标准 skills 路径）
    private var agentsSkillsDir: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".agents/skills")
    }

    /// LaunchX 本地主副本目录
    private var localSkillsDir: URL {
        store.skillsDir
    }

    // MARK: - 数据加载

    private func loadData() {
        skills = store.loadSkills()
        repos = store.loadSkillRepos()
    }

    private func persistSkills() throws {
        try store.saveSkills(skills)
    }

    private func persistRepos() {
        try? store.saveSkillRepos(repos)
    }

    // MARK: - 仓库管理

    func initDefaultRepos() {
        persistRepos()
    }

    func addRepo(owner: String, name: String, branch: String = "main") {
        let repo = CodexSkillRepo(owner: owner, name: name, branch: branch)
        if !repos.contains(where: { $0.owner == owner && $0.name == name }) {
            repos.append(repo)
            persistRepos()
        }
    }

    func removeRepo(_ repo: CodexSkillRepo) {
        repos.removeAll { $0.id == repo.id }
        persistRepos()
    }

    // MARK: - Skills 发现

    func discoverSkills() async {
        isLoading = true
        defer { isLoading = false }

        discoveredSkills = []

        let enabledRepos = repos.filter { $0.isEnabled }
        guard !enabledRepos.isEmpty else { return }

        await withTaskGroup(of: [CodexDiscoveredSkill].self) { group in
            for repo in enabledRepos {
                group.addTask { [weak self] in
                    guard let self = self else { return [] }
                    return await self.discoverSkillsFromRepo(repo)
                }
            }

            for await repoSkills in group {
                discoveredSkills.append(contentsOf: repoSkills)
                discoveredSkills.sort { $0.name.lowercased() < $1.name.lowercased() }
            }
        }
    }

    private func discoverSkillsFromRepo(_ repo: CodexSkillRepo) async -> [CodexDiscoveredSkill] {
        let apiUrl = "https://api.github.com/repos/\(repo.owner)/\(repo.name)/git/trees/\(repo.branch)?recursive=1"

        guard let url = URL(string: apiUrl) else { return [] }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            return []
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tree = json["tree"] as? [[String: Any]] else {
            return []
        }

        let skillFiles = tree.filter { item in
            (item["path"] as? String)?.hasSuffix("SKILL.md") == true
        }

        let currentSkills = self.skills

        var repoSkills: [CodexDiscoveredSkill] = await withTaskGroup(of: CodexDiscoveredSkill?.self) { group in
            for file in skillFiles {
                guard let path = file["path"] as? String else { continue }
                let directory = path.replacingOccurrences(of: "/SKILL.md", with: "")
                let rawUrl = "https://raw.githubusercontent.com/\(repo.owner)/\(repo.name)/\(repo.branch)/\(path)"

                group.addTask { [weak self] in
                    guard let self = self else { return nil }

                    var skillName = directory.components(separatedBy: "/").last ?? directory
                    var skillDesc: String? = nil

                    if let contentUrl = URL(string: rawUrl) {
                        if let contentData = try? await URLSession.shared.data(from: contentUrl).0,
                           let content = String(data: contentData, encoding: .utf8) {
                            if let metadata = self.parseYAMLFrontmatter(content) {
                                skillName = metadata.name ?? skillName
                                skillDesc = metadata.description
                            }
                        }
                    }

                    let sanitizedDir = self.sanitizeDirectory(directory)

                    return CodexDiscoveredSkill(
                        name: skillName,
                        description: skillDesc,
                        directory: sanitizedDir,
                        repoOwner: repo.owner,
                        repoName: repo.name,
                        repoBranch: repo.branch,
                        readmeUrl: rawUrl
                    )
                }
            }

            var results: [CodexDiscoveredSkill] = []
            for await skill in group {
                if let skill = skill {
                    results.append(skill)
                }
            }
            return results
        }

        return repoSkills
    }

    // MARK: - YAML Frontmatter 解析

    private struct SkillMetadata {
        let name: String?
        let description: String?
    }

    nonisolated private func parseYAMLFrontmatter(_ content: String) -> SkillMetadata? {
        guard content.hasPrefix("---") else { return nil }

        let lines = content.components(separatedBy: "\n")
        var endIdx: Int?
        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                endIdx = i
                break
            }
        }
        guard let end = endIdx else { return nil }

        var name: String?
        var description: String?

        for i in 1..<end {
            let line = lines[i]
            if line.hasPrefix("name:") {
                name = line.replacingOccurrences(of: "name:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("description:") {
                description = line.replacingOccurrences(of: "description:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        return SkillMetadata(name: name, description: description)
    }

    // MARK: - 安装

    func installSkill(_ discovered: CodexDiscoveredSkill) async throws {
        let sanitizedDir = sanitizeDirectory(discovered.directory)
        if skills.contains(where: {
            $0.repoOwner == discovered.repoOwner &&
            $0.repoName == discovered.repoName &&
            $0.directory == sanitizedDir
        }) {
            return
        }

        guard let url = URL(string: discovered.readmeUrl) else { return }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else { return }

        // 保存到本地主副本
        let localDir = localSkillsDir.appendingPathComponent(sanitizedDir)
        try fileManager.createDirectory(at: localDir, withIntermediateDirectories: true)
        let skillFile = localDir.appendingPathComponent("SKILL.md")
        try content.write(to: skillFile, atomically: true, encoding: .utf8)

        // symlink 到 ~/.agents/skills/
        try createSkillLink(sanitizedDir)

        let skill = CodexSkill(
            name: discovered.name,
            skillDescription: discovered.description,
            directory: sanitizedDir,
            repoOwner: discovered.repoOwner,
            repoName: discovered.repoName,
            repoBranch: discovered.repoBranch,
            readmeUrl: discovered.readmeUrl,
            isEnabled: true
        )
        skills.append(skill)
        try persistSkills()
    }

    private func createSkillLink(_ directory: String) throws {
        let sanitizedDir: String
        if directory.hasPrefix("skills/") {
            sanitizedDir = String(directory.dropFirst("skills/".count))
        } else {
            sanitizedDir = directory
        }

        let targetDir = agentsSkillsDir.appendingPathComponent(sanitizedDir)
        let sourceDir = localSkillsDir.appendingPathComponent(sanitizedDir)

        try? fileManager.createDirectory(at: agentsSkillsDir, withIntermediateDirectories: true)

        if fileManager.fileExists(atPath: targetDir.path) {
            try? fileManager.removeItem(at: targetDir)
        }

        do {
            try fileManager.createSymbolicLink(atPath: targetDir.path, withDestinationPath: sourceDir.path)
        } catch {
            try? fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
            let sourceFile = sourceDir.appendingPathComponent("SKILL.md")
            let targetFile = targetDir.appendingPathComponent("SKILL.md")
            try? fileManager.copyItem(at: sourceFile, to: targetFile)
        }
    }

    // MARK: - 卸载

    func uninstallSkill(_ skill: CodexSkill) throws {
        let targetDir = agentsSkillsDir.appendingPathComponent(skill.directory)
        try? fileManager.removeItem(at: targetDir)

        let localDir = localSkillsDir.appendingPathComponent(skill.directory)
        try? fileManager.removeItem(at: localDir)

        skills.removeAll { $0.id == skill.id }
        try persistSkills()
    }

    // MARK: - 启用/禁用

    func toggleEnabled(_ skill: CodexSkill) throws {
        guard let index = skills.firstIndex(where: { $0.id == skill.id }) else { return }
        skills[index].isEnabled.toggle()

        if skills[index].isEnabled {
            try createSkillLink(skill.directory)
        } else {
            let targetDir = agentsSkillsDir.appendingPathComponent(skill.directory)
            try? fileManager.removeItem(at: targetDir)
        }

        try persistSkills()
    }

    // MARK: - 扫描与导入

    struct UnmanagedCodexSkill: Identifiable {
        let id = UUID()
        let name: String
        let description: String?
        let directory: String
        let url: URL
    }

    func scanUnmanagedSkills() -> [UnmanagedCodexSkill] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: agentsSkillsDir, includingPropertiesForKeys: nil) else {
            return []
        }

        var unmanaged: [UnmanagedCodexSkill] = []
        for url in contents {
            let dirName = url.lastPathComponent
            if skills.contains(where: { $0.directory == dirName }) { continue }

            let skillFile = url.appendingPathComponent("SKILL.md")
            if fileManager.fileExists(atPath: skillFile.path) {
                var name = dirName
                var desc: String? = nil
                if let content = try? String(contentsOf: skillFile, encoding: .utf8),
                   let metadata = parseYAMLFrontmatter(content) {
                    name = metadata.name ?? name
                    desc = metadata.description
                }
                unmanaged.append(UnmanagedCodexSkill(name: name, description: desc, directory: dirName, url: url))
            }
        }
        return unmanaged
    }

    func importSkill(_ unmanaged: UnmanagedCodexSkill) throws {
        let localDir = localSkillsDir.appendingPathComponent(unmanaged.directory)
        try? fileManager.createDirectory(at: localDir, withIntermediateDirectories: true)
        let sourceFile = unmanaged.url.appendingPathComponent("SKILL.md")
        let targetFile = localDir.appendingPathComponent("SKILL.md")
        try? fileManager.copyItem(at: sourceFile, to: targetFile)

        let skill = CodexSkill(
            name: unmanaged.name,
            skillDescription: unmanaged.description,
            directory: unmanaged.directory,
            repoOwner: "",
            repoName: "",
            isEnabled: true
        )
        skills.append(skill)
        try? persistSkills()
    }

    // MARK: - 同步

    func syncAllEnabled() {
        for skill in skills where skill.isEnabled {
            try? createSkillLink(skill.directory)
        }
    }

    nonisolated private func sanitizeDirectory(_ directory: String) -> String {
        if directory.hasPrefix("skills/") {
            return String(directory.dropFirst("skills/".count))
        }
        return directory
    }
}
