## Why

搜索面板的 Claude Code Switcher 模式存在两个 bug：
1. 非激活 Provider 行的图标与文字垂直不对齐，图标始终 centerY 居中但文字走的是 top 对齐 + 小字体，导致视觉上图标和文字错位。
2. 通过快捷键连续在自定义扩展界面和 ClaudeCode 扩展界面之间切换时，由于 `handleEnterClaudeCodeModeDirectly()` 使用了 `asyncAfter` 延迟，在快速连续操作时产生竞态条件，导致界面显示错误（如 Zed 扩展界面展示了 ClaudeCode 的内容）。

## What Changes

- **Provider 行对齐修复**：在 `ResultCellView.configure()` 的垂直居中条件中增加 `isClaudeCodeItem` 标志，使所有 Claude Code 项目（Provider、MCP、Skills）的图标和文字保持水平居中对齐。
- **扩展切换竞态修复**：移除 `handleEnterClaudeCodeModeDirectly()` 中的 `DispatchQueue.main.asyncAfter` 延迟，改为同步执行模式切换，消除快速连续切换时的竞态条件。

## Capabilities

### New Capabilities

（无新增能力）

### Modified Capabilities

- `shared-ui-components`：修复 ResultCellView 中 Claude Code 项目的垂直对齐逻辑
- `modular-architecture`：修复扩展模式切换的竞态条件，提升状态管理可靠性

## Impact

- **受影响文件**：
  - `LaunchX/Views/Search/ResultCellView.swift` — 对齐逻辑修改
  - `LaunchX/Views/Search/SearchPanelViewController+Modes.swift` — 竞态修复
- **回滚计划**：两个修改均为独立的单点修复，回滚只需还原对应 git commit 即可，不影响其他功能
- **风险**：低。对齐修复仅影响 Claude Code 项目的布局渲染；竞态修复仅移除了一个不必要的延迟调用
