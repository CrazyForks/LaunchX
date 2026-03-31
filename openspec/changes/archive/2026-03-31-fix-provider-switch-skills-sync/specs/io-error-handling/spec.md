## ADDED Requirements

### Requirement: I/O 操作错误传播

所有涉及文件读写的 Service 方法（写入 settings.json、写入 ~/.claude.json、持久化 JSON 数据、创建 symlink）MUST 使用 `throws` 向上层传播错误，而非 `try?` 静默吞掉。

#### Scenario: writeClaudeSettings 写入失败时抛出错误
- **WHEN** `writeClaudeSettings` 因文件锁定或权限问题无法写入 `~/.claude/settings.json`
- **THEN** 方法 SHALL 抛出错误，调用方能在 catch 块中处理

#### Scenario: DataStore 持久化失败时抛出错误
- **WHEN** `ClaudeDataStore.saveProviders`、`saveMcpServers`、`saveSkills` 写入 JSON 文件失败
- **THEN** 方法 SHALL 抛出错误，Service 层能感知并反馈给用户

### Requirement: Provider 切换原子性

`switchProvider` 操作 MUST 保证原子性：要么配置切换完全成功（旧 provider 回填 + 新 provider 写入 settings.json + 持久化），要么完全回滚（旧 provider 数据不变，settings.json 不变）。

#### Scenario: writeClaudeSettings 失败时回滚 backfill
- **WHEN** `backfillCurrentProvider` 已执行（覆盖了旧 provider 的 settingsConfig），但后续 `writeClaudeSettings` 失败
- **THEN** 旧 provider 的 settingsConfig SHALL 恢复为 backfill 前的值，providers 数组中 isCurrent 标志也恢复

#### Scenario: 切换成功后 settings.json 被更新
- **WHEN** 用户点击「启用」一个新 provider
- **THEN** `~/.claude/settings.json` 的 `env` 字段 SHALL 更新为新 provider 的 settingsConfig 内容

### Requirement: writeClaudeSettings 安全覆盖

`writeClaudeSettings` MUST 在写入前先删除旧文件再 moveItem，确保文件被正确替换。

#### Scenario: settings.json 已存在时能正确覆盖
- **WHEN** `~/.claude/settings.json` 已存在且包含旧的 env 配置
- **THEN** 调用 `writeClaudeSettings` 后，文件内容 SHALL 更新为新 provider 的 env 配置

### Requirement: MCP syncToClaude 确实生效

`syncToClaude` 写入 `~/.claude.json` 后，文件中的 `mcpServers` 字段 SHALL 包含所有启用的 MCP 服务器配置。

#### Scenario: 添加 MCP server 后 ~/.claude.json 被更新
- **WHEN** 用户添加一个新的 MCP server 并启用
- **THEN** `~/.claude.json` 的顶层 `mcpServers` 字段 SHALL 包含该 server 的配置

#### Scenario: mcp_servers.json 数据不丢失
- **WHEN** 用户添加、编辑或删除 MCP server
- **THEN** `mcp_servers.json` SHALL 被正确持久化到 `~/Library/Application Support/LaunchX/claude/` 目录

### Requirement: Skills 目录路径正确

Skills 的 symlink 或文件副本 MUST 创建在 `~/.claude/skills/{directory}/` 下，不允许出现 `skills/skills/` 的嵌套结构。

#### Scenario: 安装 Skill 后路径不嵌套
- **WHEN** 用户安装一个 directory 为 `skill-creator` 的 skill
- **THEN** symlink 目标 SHALL 为 `~/.claude/skills/skill-creator/`，而非 `~/.claude/skills/skills/skill-creator/`

#### Scenario: syncAllEnabled 修复已安装 Skills 的路径
- **WHEN** 用户切换 provider 触发 `syncAllEnabled`
- **THEN** 所有已启用 skills 的 symlink SHALL 指向正确路径

### Requirement: Skills 数据持久化

`skills.json` MUST 正确持久化到 `~/Library/Application Support/LaunchX/claude/skills.json`。

#### Scenario: 安装 Skill 后 skills.json 包含记录
- **WHEN** 用户安装一个 skill
- **THEN** `skills.json` SHALL 包含该 skill 的记录（name、directory、isEnabled 等）

### Requirement: UI 错误反馈

所有可能失败的配置操作（切换 Provider、添加/编辑 MCP server、安装 Skill）MUST 在失败时向用户显示明确的错误提示。

#### Scenario: Provider 切换失败显示错误
- **WHEN** 用户点击「启用」Provider 但操作失败
- **THEN** UI SHALL 显示 alert 弹窗，包含错误描述信息

#### Scenario: MCP 操作失败显示错误
- **WHEN** 用户添加或编辑 MCP server 但持久化或同步失败
- **THEN** UI SHALL 显示 alert 弹窗，包含错误描述信息
