## ADDED Requirements

### Requirement: Codex Skill 数据模型
系统 SHALL 提供 `CodexSkill` 模型，包含以下字段：`id`（UUID）、`name`（skill 名称）、`skillDescription`（描述，用于隐式匹配）、`directory`（本地存储目录名）、`repoOwner`（GitHub 仓库 owner）、`repoName`（GitHub 仓库名）、`repoBranch`（分支，默认 "main"）、`readmeUrl`（SKILL.md 的 GitHub raw URL）、`isEnabled`（启用状态）、`installedAt`（安装时间）。模型 SHALL 遵循 `Codable` + `Identifiable` + `Equatable`。

#### Scenario: 创建 Skill 实例
- **WHEN** 用户从 GitHub 仓库发现并安装一个 skill
- **THEN** 系统创建 `CodexSkill` 实例，记录来源仓库信息和安装时间

### Requirement: Skill 仓库管理
系统 SHALL 支持管理多个 Skill 来源仓库（`CodexSkillRepo` 模型），默认仓库为 `openai/codex`（如果 OpenAI 官方有 skills 仓库）或用户自定义的仓库。每个仓库包含 `owner`、`name`、`branch`、`isEnabled` 字段。

#### Scenario: 添加自定义 Skill 仓库
- **WHEN** 用户添加一个 GitHub 仓库作为 Skill 来源（owner="myorg"，name="codex-skills"）
- **THEN** 系统创建 `CodexSkillRepo` 记录，后续 discoverSkills 时会扫描该仓库

#### Scenario: 禁用仓库
- **WHEN** 用户禁用一个 Skill 仓库
- **THEN** 系统停止扫描该仓库，但已安装的 skills 不受影响

### Requirement: Skill 发现（GitHub API 扫描）
系统 SHALL 支持从已启用的 GitHub 仓库中发现 Skills：使用 GitHub Git Trees API（`/repos/{owner}/{repo}/git/trees/{branch}?recursive=1`）扫描所有 `SKILL.md` 文件，并行下载并解析 YAML frontmatter 获取 name 和 description，展示为可安装的 skill 列表。

#### Scenario: 从仓库发现 Skills
- **WHEN** 用户触发 Skill 发现操作
- **THEN** 系统并行扫描所有已启用的仓库，收集所有包含 SKILL.md 的目录，解析 frontmatter，返回 `DiscoveredCodexSkill` 列表

#### Scenario: 网络请求失败
- **WHEN** GitHub API 请求因网络问题失败
- **THEN** 系统显示错误提示，已成功获取的结果仍然展示

### Requirement: Skill 安装
系统 SHALL 支持安装 Skill：从 GitHub 下载 `SKILL.md` 文件，保存到本地 `~/Library/Application Support/LaunchX/codex/skills/<directory>/SKILL.md`，创建符号链接从 `~/.agents/skills/<directory>` 指向本地副本（失败时回退到文件复制）。

#### Scenario: 安装 Skill
- **WHEN** 用户选择安装一个发现的 Skill（directory="code-review"）
- **THEN** 系统下载 SKILL.md，保存到本地，创建 `~/.agents/skills/code-review/` 符号链接

#### Scenario: 符号链接创建失败
- **WHEN** 无法创建符号链接（例如权限问题）
- **THEN** 系统回退为直接复制文件到 `~/.agents/skills/<directory>/`

### Requirement: Skill 启用/禁用
系统 SHALL 支持切换 Skill 的启用状态：启用时创建符号链接，禁用时移除符号链接。

#### Scenario: 禁用已安装的 Skill
- **WHEN** 用户禁用一个已启用的 Skill
- **THEN** 系统移除 `~/.agents/skills/<directory>` 符号链接，更新 `isEnabled` 为 false

#### Scenario: 重新启用 Skill
- **WHEN** 用户启用一个已禁用的 Skill
- **THEN** 系统重新创建符号链接，更新 `isEnabled` 为 true

### Requirement: Skill 卸载
系统 SHALL 支持卸载 Skill：移除符号链接/复制的文件、删除本地存储目录、从数据记录中移除。

#### Scenario: 卸载 Skill
- **WHEN** 用户卸载一个已安装的 Skill
- **THEN** 系统移除 `~/.agents/skills/<directory>` 中的文件，删除本地存储目录，从 skills.json 中移除记录

### Requirement: 扫描未管理的 Skills
系统 SHALL 支持扫描 `~/.agents/skills/` 目录中未被 LaunchX 管理的 Skill（即不在 skills.json 记录中的目录），提供导入功能将其纳入管理。

#### Scenario: 发现未管理的 Skill
- **WHEN** 用户触发扫描未管理 Skills
- **THEN** 系统列出 `~/.agents/skills/` 中不在管理记录中的目录

#### Scenario: 导入未管理的 Skill
- **WHEN** 用户选择导入一个未管理的 Skill
- **THEN** 系统将本地文件复制到 LaunchX 管理目录，创建管理记录

### Requirement: Skill 全量同步
系统 SHALL 支持 `syncAllEnabled()` 操作，为所有已启用的 Skills 重新创建符号链接，确保 `~/.agents/skills/` 目录状态与数据一致。

#### Scenario: 批量同步 Skills
- **WHEN** Provider 切换或手动触发同步
- **THEN** 系统遍历所有已启用的 Skills，确保每个 Skill 在 `~/.agents/skills/` 中有正确的符号链接
