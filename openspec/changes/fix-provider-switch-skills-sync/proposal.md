## Why

Provider 切换功能存在严重的数据污染 bug：点击「启用」时 `backfillCurrentProvider()` 会用 `settings.json` 的内容覆盖旧 Provider 的配置，而 `writeClaudeSettings()` 因原子写入逻辑缺陷静默失败，导致 `settings.json` 未被更新。最终结果是旧 Provider 被污染，新 Provider 的配置从未生效。

同时 MCP 服务器管理完全失效：`~/.claude.json` 中没有顶层 `mcpServers` 字段，`mcp_servers.json` 数据文件丢失，应用内所有 MCP 增删改操作无任何实际效果。

Skills 同步路径嵌套错误导致 Claude Code 无法识别已安装的 Skills，`skills.json` 为空，本地主副本目录也是空的。

三大模块共享同一根因：所有关键 I/O 操作使用 `try?` 静默忽略错误，失败时没有任何反馈。

## What Changes

### Provider 切换修复
- 修复 `writeClaudeSettings` 的原子写入逻辑：先删除旧文件再 `moveItem`（与 MCP sync 的正确实现保持一致）
- 修复 `backfillCurrentProvider` 的设计缺陷：写入失败时回滚 backfill 操作，避免数据污染
- `switchProvider` 改为 throws 向上层传播错误，UI 层显示失败提示

### MCP 管理修复
- 修复 `syncToClaude`：确保正确写入 `~/.claude.json` 的顶层 `mcpServers` 字段（当前 `readClaudeJson` 读取整个文件后 `syncToClaude` 用 `config["mcpServers"] = mcpServers` 覆盖，理论上应该可以，但需要验证 `mcpServers.json` 持久化是否正常）
- 修复 MCP 数据持久化：`mcp_servers.json` 不存在说明 `persistData` 的 `try?` 吞掉了写入错误
- MCP CRUD 操作添加错误反馈

### Skills 同步修复
- 修复 Skills 目录路径嵌套错误：`~/.claude/skills/skills/xxx` → `~/.claude/skills/xxx`
- 修复 `skills.json` 和本地主副本的持久化问题
- `syncAllEnabled` 添加错误反馈

### 错误处理统一
- 为所有关键 I/O 操作添加错误传播机制，替代 `try?` 静默模式
- UI 层统一显示操作失败提示

## Capabilities

### New Capabilities
- `io-error-handling`: 关键文件 I/O 操作的错误传播与用户反馈机制，替代现有的 `try?` 静默模式

### Modified Capabilities
（无现有 spec 需要修改）

## Impact

- `ClaudeProviderService.swift`: `switchProvider`、`writeClaudeSettings`、`backfillCurrentProvider` 方法
- `ClaudeMcpService.swift`: `syncToClaude`、`persistData`、所有 CRUD 方法
- `ClaudeSkillService.swift`: `createSkillLink`、`syncAllEnabled`、`installSkill` 方法
- `ClaudeDataStore.swift`: 所有持久化方法需要错误传播
- `ProviderListView.swift`: 添加操作失败时的错误提示
- `McpServerListView.swift`: 添加操作失败时的错误提示
- 用户数据：需要考虑已损坏的 providers.json 和错误路径下的 skills 文件的迁移/修复

## Rollback Plan

所有修改限于 Service 层和 View 层，不涉及数据格式变更。如果出现问题：
1. Provider 相关：`providers.json` 和 `settings.json` 均有备份机制，可通过备份恢复
2. MCP 相关：`~/.claude.json` 在 sync 前已有读取逻辑，最坏情况下手动编辑即可
3. Skills 相关：删除错误的嵌套目录后重新安装即可
