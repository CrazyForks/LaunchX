## Context

Claude Code Switcher 是一个通过快捷键触发的搜索面板弹窗，用户可以在其中快速切换 Provider、启用/禁用 MCP 服务器和 Skill。

当前实现中，`handleClaudeCodeItemSelected()` 执行 toggle 操作后调用 `loadClaudeCodeItems()` 重建整个 `results` 数组、重置 `selectedIndex = 0`、调用 `tableView.reloadData()` 并 `scrollRowToVisible(0)`。这导致每次操作后列表滚回顶部。

## Goals / Non-Goals

**Goals:**
- Toggle 操作后保持列表滚动位置不变
- 只更新被操作行的视觉状态（图标、displayAlias），其他行不受影响
- 最小化代码改动

**Non-Goals:**
- 不改变 `loadClaudeCodeItems()` 本身的逻辑（首次加载和搜索过滤仍走完整重建）
- 不改变 toggle 的业务逻辑（`switchProvider`、`toggleEnabled`）

## Decisions

### 就地更新 results 行 vs 传递 targetItemId

**选择：就地更新 results 对应行 + 单行刷新**

替代方案：给 `loadClaudeCodeItems()` 添加 `targetItemId` 参数，重建后滚到目标项。
- 放弃原因：仍然做了不必要的全量重建（创建 NSImage、构建 SearchResult），只是修复了滚动位置，没有解决"刷新"本身。

### 实现方式

在 `handleClaudeCodeItemSelected()` 中，每个 case 执行完业务操作后：

1. 根据新的状态生成新的 icon 和 displayAlias
2. 找到 `results` 中对应的行（通过 `claudeCodeItemId` 匹配）
3. 用新数据替换该行
4. 调用 `tableView.reloadData(forRowIndexes:columnIndexes:)` 只刷新该行

对于 Provider 切换，还需要更新旧的当前 Provider 行（从激活变为非激活），需要额外刷新两行。

## Risks / Trade-offs

- **[results 与 service 数据不一致]** → toggle 只改了 results 的显示数据，service 的 `@Published` 数组已经更新。下次调用 `loadClaudeCodeItems()` 时会同步。不存在真实不一致风险。
- **[搜索过滤后的 toggle]** → `filterClaudeCodeItems` 搜索时会调用 `loadClaudeCodeItems()` 全量重建，此时数据一定是最新的，无风险。
