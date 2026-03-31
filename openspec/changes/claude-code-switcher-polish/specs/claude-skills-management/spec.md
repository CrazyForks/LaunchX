## MODIFIED Requirements

### Requirement: Skill 安装
系统 SHALL 支持一键安装 Skills 到 Claude Code，安装过程 MUST 使用异步网络请求，不得阻塞主线程。

#### Scenario: 从仓库安装 Skill
- **WHEN** 用户选择一个可用 Skill 并点击安装
- **THEN** 系统 SHALL：
  1. 使用 URLSession 异步下载 Skill 的 SKILL.md 内容（不阻塞主线程）
  2. 保存到 `~/Library/Application Support/LaunchX/claude/skills/<directory>/SKILL.md`
  3. 创建 symlink：`~/.claude/skills/<directory>` → LaunchX skills 目录中的对应文件夹
  4. 记录安装信息到 skills.json

#### Scenario: Symlink 失败降级
- **WHEN** 创建 symlink 失败（权限等原因）
- **THEN** 系统 SHALL 降级为文件复制模式，将 SKILL.md 直接复制到 `~/.claude/skills/<directory>/`

#### Scenario: 已安装 Skill 更新
- **WHEN** 用户对已安装的 Skill 重新安装（源仓库有更新）
- **THEN** 系统 SHALL 异步下载最新内容覆盖本地主副本，并同步到 `~/.claude/skills/`

#### Scenario: 安装过程不阻塞 UI
- **WHEN** 用户点击安装按钮
- **THEN** 整个安装过程（网络下载、文件写入）MUST 在后台执行，主线程保持响应，不出现 spinning beach ball

### Requirement: Skill 发现与浏览
系统 SHALL 支持从配置的 GitHub 仓库中发现可用的 Skills，发现过程 MUST 使用异步网络请求。

#### Scenario: 浏览可用 Skills
- **WHEN** 用户打开 Skills 浏览界面
- **THEN** 系统从所有已配置的 GitHub 仓库中异步扫描包含 SKILL.md 的文件，展示可用 Skills 列表，不阻塞主线程

#### Scenario: Skill 详情查看
- **WHEN** 用户点击一个可用 Skill
- **THEN** 系统展示 Skill 的名称、描述、来源仓库信息，并提供安装按钮

#### Scenario: GitHub API 限流处理
- **WHEN** GitHub API 请求频率超过限制
- **THEN** 系统 SHALL 显示友好的错误提示，建议用户稍后重试
