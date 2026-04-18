## 1. 重构 handleClaudeCodeItemSelected

- [x] 1.1 提取生成 Claude Code 行图标和 displayAlias 的辅助方法（从 `loadClaudeCodeItems()` 中复用），避免重复构建 SearchResult 的 icon 逻辑
- [x] 1.2 修改 `.provider` case：切换 Provider 后，就地更新 `results` 中新 Provider 行和旧 Provider 行的 icon/displayAlias，用 `tableView.reloadData(forRowIndexes:columnIndexes:)` 刷新这两行，移除 `loadClaudeCodeItems()` 调用
- [x] 1.3 修改 `.mcp` case：toggle 后就地更新 `results` 中对应行的 icon/displayAlias，单行刷新，移除 `loadClaudeCodeItems()` 调用
- [x] 1.4 修改 `.skill` case：toggle 后就地更新 `results` 中对应行的 icon/displayAlias，单行刷新，移除 `loadClaudeCodeItems()` 调用

## 2. 验证

- [x] 2.1 构建项目确认无编译错误
- [ ] 2.2 手动测试：在 Switcher 中连续 toggle 多个 MCP/Skill，确认滚动位置不变、图标和状态文字正确更新
