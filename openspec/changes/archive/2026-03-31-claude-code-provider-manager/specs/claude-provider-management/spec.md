## ADDED Requirements

### Requirement: Provider 数据模型
系统 SHALL 定义 ClaudeProvider 数据模型，包含以下字段：
- id: 唯一标识符（UUID）
- name: Provider 显示名称
- settingsConfig: JSON 字典，包含 env 变量（ANTHROPIC_AUTH_TOKEN、ANTHROPIC_BASE_URL、ANTHROPIC_MODEL 等）
- category: 分类（official、cn_official、aggregator、third_party、cloud_provider）
- websiteUrl: 官网链接（可选）
- notes: 备注（可选）
- icon: 图标标识（可选）
- iconColor: 图标颜色（可选）
- isCurrent: 是否为当前激活的 Provider
- createdAt: 创建时间戳
- sortIndex: 排序索引

#### Scenario: 创建 Provider 实例
- **WHEN** 用户通过表单填写 Provider 信息并提交
- **THEN** 系统生成唯一 id，保存到 providers.json，settingsConfig 中至少包含 ANTHROPIC_AUTH_TOKEN 或 ANTHROPIC_API_KEY

#### Scenario: Provider 数据持久化
- **WHEN** Provider 数据发生变化（增删改）
- **THEN** 系统 SHALL 将变更持久化到 `~/Library/Application Support/LaunchX/claude/providers.json`

### Requirement: Provider 预设系统
系统 SHALL 提供内置 Provider 预设，包含至少以下预设：
- Claude Official（官方登录）
- OpenRouter
- SiliconFlow
- DMXAPI
- AiHubMix
- DeepSeek
- 以及其他第三方/云服务商/聚合平台预设

每个预设 SHALL 包含：id、name、category、默认 env 配置（不含 API Key）、可选的 baseUrl、可选的 model。

#### Scenario: 从预设创建 Provider
- **WHEN** 用户选择一个预设并填入 API Key
- **THEN** 系统基于预设模板创建 Provider，将用户填入的 API Key 设置到对应 env 字段

#### Scenario: 预设列表展示
- **WHEN** 用户打开添加 Provider 界面
- **THEN** 系统按 category 分组展示所有内置预设，用户可以选择一个预设快速创建

### Requirement: Provider CRUD 操作
系统 SHALL 支持对 Provider 的完整增删改查操作。

#### Scenario: 添加自定义 Provider
- **WHEN** 用户手动填写 Provider 名称、API Key、Base URL 等信息并保存
- **THEN** 系统创建新的 Provider 记录并持久化

#### Scenario: 编辑 Provider
- **WHEN** 用户修改已有 Provider 的配置信息
- **THEN** 系统更新 Provider 记录。如果编辑的是当前激活的 Provider，系统 SHALL 同步更新 `~/.claude/settings.json`

#### Scenario: 删除 Provider
- **WHEN** 用户删除一个非当前激活的 Provider
- **THEN** 系统从 providers.json 中移除该记录

#### Scenario: 删除当前激活的 Provider
- **WHEN** 用户尝试删除当前激活的 Provider
- **THEN** 系统 SHALL 拒绝删除操作并提示用户先切换到其他 Provider

#### Scenario: 查询 Provider 列表
- **WHEN** 用户打开 Provider 管理界面
- **THEN** 系统展示所有 Provider，当前激活的 Provider 标记为选中状态

### Requirement: Provider 切换
系统 SHALL 支持在多个 Provider 之间切换，切换时自动更新 Claude Code 的配置文件。

#### Scenario: 切换到新 Provider
- **WHEN** 用户选择一个非当前激活的 Provider 并点击"启用"
- **THEN** 系统 SHALL 执行以下步骤：
  1. 读取当前 `~/.claude/settings.json`，将配置回填到当前激活的 Provider（backfill）
  2. 备份当前 `~/.claude/settings.json` 到 backups 目录
  3. 将新 Provider 的 settingsConfig 写入 `~/.claude/settings.json`
  4. 更新 providers.json 中的 isCurrent 标志
  5. 触发 MCP 同步和 Skills 同步

#### Scenario: 配置回填（Backfill）
- **WHEN** Provider 切换前，系统检测到 `~/.claude/settings.json` 中的配置与当前 Provider 的 settingsConfig 不同
- **THEN** 系统 SHALL 将 `~/.claude/settings.json` 中的最新配置保存回当前 Provider 的 settingsConfig

#### Scenario: 首次使用导入
- **WHEN** LaunchX 首次打开 Claude Code 管理功能，且 `~/.claude/settings.json` 已存在
- **THEN** 系统 SHALL 自动读取该文件并创建一个名为"default"的 Provider，标记为当前激活

### Requirement: 配置备份与回滚
系统 SHALL 在每次 Provider 切换前自动备份配置文件。

#### Scenario: 自动备份
- **WHEN** 用户执行 Provider 切换操作
- **THEN** 系统 SHALL 在写入新配置前，将当前 `~/.claude/settings.json` 备份到 `~/Library/Application Support/LaunchX/claude/backups/` 目录，文件名包含时间戳

#### Scenario: 备份轮转
- **WHEN** 备份文件数量超过 10 个
- **THEN** 系统 SHALL 自动删除最旧的备份文件

#### Scenario: 手动回滚
- **WHEN** 用户选择一个备份并点击"恢复"
- **THEN** 系统 SHALL 将备份文件内容写回 `~/.claude/settings.json`，同时更新对应的 Provider 配置

### Requirement: 配置文件原子写入
系统 SHALL 使用原子写入策略操作 Claude Code 的配置文件，防止配置损坏。

#### Scenario: 原子写入 settings.json
- **WHEN** 系统需要写入 `~/.claude/settings.json`
- **THEN** 系统 SHALL 先写入临时文件，确认写入成功后通过 rename 操作替换原文件

### Requirement: Provider 设置界面
系统 SHALL 在设置页的高级扩展中提供 Claude Code Provider 管理界面。

#### Scenario: Provider 列表视图
- **WHEN** 用户打开 Claude Code 设置页面
- **THEN** 系统展示 Provider 列表，每个 Provider 显示名称、分类图标、激活状态，当前激活的 Provider 高亮显示

#### Scenario: Provider 编辑表单
- **WHEN** 用户添加或编辑 Provider
- **THEN** 系统展示表单，包含：名称、API Key（密码输入框）、Base URL、模型名称、分类、备注等字段。预设创建时自动填充模板值
