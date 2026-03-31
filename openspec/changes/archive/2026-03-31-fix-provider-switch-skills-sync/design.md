## Context

Provider 切换、MCP 管理、Skills 同步是 LaunchX 管理 Claude Code 配置的三大核心功能。三者共享 `ClaudeDataStore` 进行 JSON 持久化，共享 `@StateObject + singleton` 模式在 View 层绑定数据。当前三者都有 I/O 静默失败的共性问题，且各自有独立的逻辑 bug。

## Goals / Non-Goals

**Goals:**
- Provider 切换时 `settings.json` 确实被更新，旧 Provider 数据不被污染
- MCP CRUD 操作确实写入 `~/.claude.json`，持久化数据不丢失
- Skills 同步到正确路径 `~/.claude/skills/{name}/`，数据不丢失
- 所有操作失败时用户得到明确反馈

**Non-Goals:**
- 不重构 `@StateObject + singleton` 模式（改为 `@EnvironmentObject` 等方式），这是另一个话题
- 不处理 Claude Code 进程锁定 settings.json 的并发问题（运行时边界情况）
- 不修改 ClaudeProvider 数据模型（如 Equatable 实现）

## Decisions

### D1: writeClaudeSettings 采用"安全覆盖"模式

当前 `writeClaudeSettings` 使用 `Data.write(atomic) + moveItem`，如果 moveItem 失败则 settings.json 不变但也没反馈。

改为：参照 `ClaudeMcpService.syncToClaude` 的正确实现，先检查旧文件是否存在并删除，再 moveItem。同时在 catch 块中向上抛出错误而非静默吞掉。

### D2: backfillCurrentProvider 改为"先备份后回滚"模式

当前 backfill 直接覆盖旧 provider 的 settingsConfig，如果后续 writeClaudeSettings 失败，旧 provider 已被污染且无法恢复。

改为：backfill 前保存旧 provider 的 settingsConfig 副本。如果后续操作失败，用副本恢复。或者更简单地：backfill 只在确认 writeClaudeSettings 成功后才持久化 providers。

### D3: switchProvider 整体改为 throws

当前 `switchProvider` 不抛出错误。改为 throws 后，UI 层的 `activateProvider` 可以在 catch 中展示错误提示。`backfillCurrentProvider` 内部的错误也向上传播。

### D4: ClaudeDataStore 持久化方法改为 throws

当前 `saveProviders`、`saveMcpServers`、`saveSkills` 的调用方全部使用 `try?` 吞掉错误。改为 throws 后，Service 层可以感知持久化失败并反馈给用户。

### D5: Skills 路径修复 - 去掉嵌套的 skills/ 层

`createSkillLink` 中 `directory` 参数包含了 `skills/` 前缀，导致最终路径为 `~/.claude/skills/skills/xxx`。修复方法：在 `createSkillLink` 和 `installSkill` 中，对 `directory` 进行 strip 处理，去掉开头的 `skills/`。或者在数据源头（`DiscoveredSkill.directory`）确保不包含 `skills/` 前缀。

### D6: 错误反馈统一机制

在 `ProviderListView`、`McpServerListView` 中，对可能失败的操作添加 try-catch，失败时设置 errorMessage 并显示 alert。当前 `ProviderListView` 已有 errorMessage 和 showError 状态变量，只需确保 catch 覆盖完整。

## Risks / Trade-offs

- **Risk**: 修复 Skills 路径后，已安装在错误路径下的 skills 不会自动迁移。需要用户重新安装或提供一次性迁移逻辑。
- **Risk**: `writeClaudeSettings` 改为先删后移，如果删除成功但 move 失败，settings.json 会丢失。缓解：在删除前先备份到临时位置，move 失败时恢复。
- **Trade-off**: 错误传播到底层会让部分方法签名从 `func foo()` 变为 `func foo() throws`，影响调用方。但影响范围可控（主要是 View 层的 Action handler）。
