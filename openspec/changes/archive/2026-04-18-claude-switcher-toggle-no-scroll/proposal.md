## Why

Claude Code Switcher 弹窗中每次按回车切换 Provider/MCP/Skill 后，整个列表会重建并滚动回顶部。用户连续操作多个项目时必须反复滚动回来，体验很差。

## What Changes

- 修改 `handleClaudeCodeItemSelected()` 中三个 case（.provider, .mcp, .skill）的 toggle 后逻辑
- Toggle 后不再调用 `loadClaudeCodeItems()` 重建整个列表
- 改为就地更新 `results` 数组中对应行的图标和 displayAlias，然后只刷新该行
- 滚动位置保持不变

## Capabilities

### New Capabilities

- `toggle-row-update`: Claude Code Switcher 中 toggle 操作后只就地更新变化行的数据与 UI，不重建列表、不重置滚动位置

### Modified Capabilities

## Impact

- `SearchPanelViewController+Modes.swift` — `handleClaudeCodeItemSelected()` 三个 case 的 toggle 后逻辑
- 回滚方案：恢复在 toggle 后调用 `loadClaudeCodeItems()` 即可回到原有行为
