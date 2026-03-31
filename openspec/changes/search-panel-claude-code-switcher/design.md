## Context

LaunchX 是一个 macOS 效率工具（类似 Raycast/Hapigo），搜索面板是其核心交互界面。目前已支持多种扩展模式（书签、2FA、实用工具、IDE 项目、网页直达等），每种模式都通过别名或全局快捷键触发。

Claude Code 的 Provider/MCP/Skills 管理功能已经完整实现在设置界面中（`ClaudeProviderService`、`ClaudeMcpService`、`ClaudeSkillService`），本次变更需要将这三个独立的切换操作分别暴露到搜索面板中，各自拥有独立的别名入口和快捷键，遵循现有的扩展模式架构。

### 当前扩展模式架构

所有扩展模式遵循统一模式：
1. **入口检测**: `SearchPanelViewController+Search.swift` 中的别名匹配方法（如 `checkBookmarkAliasMatch`）检测用户输入
2. **模式进入**: `SearchPanelViewController+Modes.swift` 中的 `enterXxxMode` / `handleEnterXxxModeDirectly` 处理模式切换
3. **UI 更新**: `updateXxxModeUI` 设置 Tag View、placeholder、搜索框状态
4. **数据加载**: `loadXxxItems` 从服务层加载数据并填充 `results` 数组
5. **模式状态**: `isInXxxMode` 布尔标志，`isInAnyExtensionMode` 计算属性汇总

## Goals / Non-Goals

**Goals:**
- 在搜索面板中新增三个独立的 Claude Code 扩展模式入口：Provider Switcher、MCP Switcher、Skills Switcher
- 每个入口有各自的别名（如 `ccp` / `mcp` / `skill`），用户输入别名匹配后选中进入对应模式
- 每个入口支持独立的全局快捷键直接进入
- Provider 模式内显示 Provider 列表，选中按回车切换
- MCP 模式内显示 MCP 服务器列表，选中按回车切换启用/禁用
- Skills 模式内显示 Skills 列表，选中按回车切换启用/禁用
- 各模式内支持搜索过滤
- 完全复用现有服务层，不重复实现业务逻辑

**Non-Goals:**
- 不在搜索面板中提供新增/编辑/删除 Provider/MCP/Skills 的功能（这些仍在设置界面）
- 不修改现有服务层的核心逻辑
- 不支持批量操作

## Decisions

### D1: 模式架构 — 一个模式状态 + 子类型枚举

**选择**: 使用一个 `isInClaudeCodeMode: Bool` 状态标志 + `claudeCodeModeType: ClaudeCodeModeType?` 枚举（`.provider` / `.mcp` / `.skill`）来区分三种子模式。三个入口各自独立，但共享同一套模式进入/退出/清理逻辑。

**理由**: 三种模式的交互模式完全一致（进入 → 显示列表 → 搜索过滤 → 回车操作），只有数据源和操作不同。共享模式状态可以避免 `isInAnyExtensionMode` 增加三个布尔值，减少重复代码。

**替代方案 A**: 三个完全独立的模式状态 `isInProviderMode` / `isInMcpMode` / `isInSkillMode` — 增加了 `isInAnyExtensionMode` 的复杂度，且大量重复的模式进入/退出代码。
**替代方案 B**: 使用独立的 SwiftUI 视图覆盖在搜索面板上 — 增加了复杂度，且与其他扩展的交互模式不一致。

### D2: 三个独立别名匹配方法

**选择**: 在 `SearchPanelViewController+Search.swift` 中新增三个独立的别名匹配方法：`checkClaudeProviderAliasMatch`、`checkClaudeMcpAliasMatch`、`checkClaudeSkillAliasMatch`，各自读取对应的别名配置。

**理由**: 每个入口有独立的别名配置，独立的匹配方法更清晰。与书签/2FA 的模式一致。

### D3: SearchResult 模型扩展

**选择**: 在 SearchResult 中新增 `isClaudeCodeEntry`（入口标识）和 `isClaudeCodeItem`（子项标识），以及 `claudeCodeItemType`（枚举：provider/mcp/skill）和 `claudeCodeItemId`（关联的实体 ID）。

**理由**: 遵循现有模式（`isBookmarkEntry` + `isBookmark`、`is2FAEntry` + `is2FACode`），每个扩展模式都有自己的入口标识和数据标识。三种入口用 `claudeCodeItemType` 区分。

### D4: 三个独立配置

**选择**: 新增 `ClaudeCodeSwitcherSettings` 配置模型，内含三组独立的配置（provider/mcp/skill 各自的 isEnabled、alias、hotKey）。

**理由**: 每个入口独立控制启用/禁用、别名、快捷键，用户可以只启用需要的入口。

### D5: 模式内搜索过滤

**选择**: 进入模式后，用户输入关键词可搜索过滤当前模式的列表项名称，使用本地内存过滤。

**理由**: 数据量小（通常几十个），本地过滤性能足够。

## Risks / Trade-offs

- **[Provider 切换耗时]** → Provider 切换涉及文件 I/O（备份配置、写入新配置、同步 MCP/Skills），可能需要几百毫秒。切换时显示 HUD 提示，操作完成后自动刷新列表。
- **[三个入口的记忆成本]** → 用户需要记住三个别名。可以通过合理的默认别名（如 `ccp`/`mcp`/`skill`）降低记忆负担。
- **[SearchResult 字段膨胀]** → SearchResult 已有多个布尔字段。长期考虑可以重构为枚举关联值，但本次变更不处理。
