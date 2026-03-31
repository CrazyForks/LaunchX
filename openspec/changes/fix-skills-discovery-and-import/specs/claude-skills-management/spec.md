## MODIFIED Requirements

### Requirement: Skill 发现与浏览
系统 SHALL 支持从配置的 GitHub 仓库中发现可用的 Skills，发现过程 MUST 使用并行请求，并支持增量 UI 更新。

#### Scenario: 浏览可用 Skills
- **WHEN** 用户打开 Skills 浏览界面并点击刷新
- **THEN** 系统从所有已配置且已启用的 GitHub 仓库中并行扫描包含 SKILL.md 的文件，展示可用 Skills 列表

#### Scenario: 多仓库结果合并
- **WHEN** 用户配置了多个启用的 Skill 仓库并点击刷新
- **THEN** 系统 SHALL 合并所有仓库的发现结果，全部显示在列表中，不丢失任何仓库的结果

#### Scenario: 增量加载展示
- **WHEN** 发现过程进行中
- **THEN** 系统 SHALL 每完成一个仓库就更新一次 Skills 列表，用户可以看到渐进式加载

#### Scenario: Skill 详情查看
- **WHEN** 用户点击一个可用 Skill
- **THEN** 系统展示 Skill 的名称、描述、来源仓库信息，并提供安装按钮

#### Scenario: GitHub API 限流处理
- **WHEN** GitHub API 请求频率超过限制或返回非 200 状态码
- **THEN** 系统 SHALL 打印警告日志（含仓库名、状态码），继续处理其他仓库，不静默吞掉错误

#### Scenario: 发现过程不阻塞 UI
- **WHEN** 用户点击刷新按钮
- **THEN** 整个发现过程 MUST 不阻塞主线程，UI 保持响应，显示加载状态指示器

### Requirement: Skill 从 Claude 导入
系统 SHALL 支持从本地 `~/.claude/skills/` 目录导入未管理的 Skills。

#### Scenario: 导入按钮显示
- **WHEN** 用户打开 Skills 设置页面（已安装 Tab）
- **THEN** 工具栏中显示「从 Claude 导入」按钮（`square.and.arrow.down` 图标）

#### Scenario: 一键导入所有未管理 Skills
- **WHEN** 用户点击「从 Claude 导入」按钮
- **THEN** 系统调用 `scanUnmanagedSkills()` 扫描 `~/.claude/skills/` 中未管理的 Skills，逐个调用 `importSkill()` 导入，完成后刷新列表

#### Scenario: 没有可导入的 Skills
- **WHEN** 用户点击「从 Claude 导入」但 `~/.claude/skills/` 中没有未管理的 Skills
- **THEN** 系统 SHALL 不做任何操作（返回导入数量为 0）
