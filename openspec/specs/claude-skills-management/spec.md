## ADDED Requirements

### Requirement: Skill 数据模型
系统 SHALL 定义 Skill 数据模型，包含以下字段：
- id: 唯一标识符（UUID）
- name: Skill 名称
- description: 描述（可选）
- directory: 在本地存储中的目录名
- repoOwner: 来源仓库 owner
- repoName: 来源仓库名称
- repoBranch: 来源分支（默认 main）
- readmeUrl: README 链接（可选）
- isEnabled: 是否启用（控制是否同步到 Claude Code）
- installedAt: 安装时间戳

#### Scenario: Skill 数据持久化
- **WHEN** Skill 数据发生变化
- **THEN** 系统 SHALL 将变更持久化到 `~/Library/Application Support/LaunchX/claude/skills.json`

### Requirement: Skill 仓库管理
系统 SHALL 支持配置和管理 Skills 来源仓库。

#### Scenario: 默认仓库初始化
- **WHEN** 首次使用 Skills 功能
- **THEN** 系统 SHALL 自动初始化默认仓库列表：anthropics/skills 等

#### Scenario: 添加自定义仓库
- **WHEN** 用户输入 GitHub 仓库的 owner 和 name 并添加
- **THEN** 系统将该仓库添加到 skill_repos.json，后续可以发现该仓库中的 Skills

#### Scenario: 移除仓库
- **WHEN** 用户移除一个 Skill 仓库
- **THEN** 系统从 skill_repos.json 中移除记录，但已安装的 Skills 不受影响

### Requirement: Skill 发现与浏览
系统 SHALL 支持从配置的 GitHub 仓库中发现可用的 Skills。

#### Scenario: 浏览可用 Skills
- **WHEN** 用户打开 Skills 浏览界面
- **THEN** 系统从所有已配置的 GitHub 仓库中扫描包含 SKILL.md（含 YAML frontmatter）的文件，展示可用 Skills 列表

#### Scenario: Skill 详情查看
- **WHEN** 用户点击一个可用 Skill
- **THEN** 系统展示 Skill 的名称、描述、来源仓库信息，并提供安装按钮

#### Scenario: GitHub API 限流处理
- **WHEN** GitHub API 请求频率超过限制
- **THEN** 系统 SHALL 显示友好的错误提示，建议用户稍后重试

### Requirement: Skill 安装
系统 SHALL 支持一键安装 Skills 到 Claude Code。

#### Scenario: 从仓库安装 Skill
- **WHEN** 用户选择一个可用 Skill 并点击安装
- **THEN** 系统 SHALL：
  1. 从 GitHub 下载 Skill 的 SKILL.md 内容
  2. 保存到 `~/Library/Application Support/LaunchX/claude/skills/<directory>/SKILL.md`
  3. 创建 symlink：`~/.claude/skills/<directory>` → LaunchX skills 目录中的对应文件夹
  4. 记录安装信息到 skills.json

#### Scenario: Symlink 失败降级
- **WHEN** 创建 symlink 失败（权限等原因）
- **THEN** 系统 SHALL 降级为文件复制模式，将 SKILL.md 直接复制到 `~/.claude/skills/<directory>/`

#### Scenario: 已安装 Skill 更新
- **WHEN** 用户对已安装的 Skill 重新安装（源仓库有更新）
- **THEN** 系统 SHALL 下载最新内容覆盖本地主副本，并同步到 `~/.claude/skills/`

### Requirement: Skill 卸载
系统 SHALL 支持卸载已安装的 Skills。

#### Scenario: 卸载 Skill
- **WHEN** 用户卸载一个已安装的 Skill
- **THEN** 系统 SHALL：
  1. 删除 `~/.claude/skills/<directory>` 中的 symlink 或复制的文件
  2. 删除 `~/Library/Application Support/LaunchX/claude/skills/<directory>` 中的主副本
  3. 从 skills.json 中移除记录

### Requirement: Skill 启用/禁用
系统 SHALL 支持单个 Skill 的启用/禁用切换。

#### Scenario: 启用 Skill
- **WHEN** 用户将一个已安装但未启用的 Skill 设置为启用
- **THEN** 系统 SHALL 在 `~/.claude/skills/<directory>` 创建 symlink 或复制文件

#### Scenario: 禁用 Skill
- **WHEN** 用户将一个启用的 Skill 设置为禁用
- **THEN** 系统 SHALL 从 `~/.claude/skills/<directory>` 中移除 symlink 或复制的文件，但保留 LaunchX 本地主副本

### Requirement: Skill 导入
系统 SHALL 支持导入已有的 Claude Code Skills。

#### Scenario: 扫描未管理的 Skills
- **WHEN** 用户触发"导入 Skills"操作
- **THEN** 系统 SHALL 扫描 `~/.claude/skills/` 目录，发现不在 skills.json 中的 Skills，列出供用户选择导入

#### Scenario: 从 ZIP 安装 Skills
- **WHEN** 用户选择一个 ZIP 文件导入
- **THEN** 系统 SHALL 解压 ZIP 文件，识别其中包含 SKILL.md 的目录，将它们作为 Skills 安装到本地

### Requirement: Skills 同步
系统 SHALL 在 Provider 切换时自动同步 Skills 状态。

#### Scenario: Provider 切换时的 Skills 同步
- **WHEN** Provider 切换成功完成
- **THEN** 系统 SHALL 遍历所有已启用的 Skills，确保它们的 symlink 或文件副本存在于 `~/.claude/skills/` 中

### Requirement: Skills 管理界面
系统 SHALL 提供 Skills 管理界面。

#### Scenario: 已安装 Skills 列表
- **WHEN** 用户打开 Skills 管理面板
- **THEN** 系统展示所有已安装的 Skills，每个显示名称、来源仓库、启用状态

#### Scenario: Skills 浏览与安装界面
- **WHEN** 用户切换到"发现"标签
- **THEN** 系统展示从配置仓库中发现的可用 Skills，已安装的标记为"已安装"，未安装的显示"安装"按钮
