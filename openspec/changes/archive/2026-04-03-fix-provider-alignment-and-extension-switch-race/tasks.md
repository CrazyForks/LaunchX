## 1. Provider 面板图标文字对齐修复

- [x] 1.1 在 `ResultCellView.swift` 的 `configure(with:isSelected:hideArrow:)` 方法中，将 `item.isClaudeCodeItem` 添加到垂直居中布局的条件判断中（约第 414 行，`if isApp || isWebLink || isUtility ...` 条件末尾追加 `|| item.isClaudeCodeItem`）
- [x] 1.2 验证所有 Claude Code 项目类型（Provider、MCP、Skills）在搜索面板中都正确垂直居中显示，图标和文字水平对齐
- [x] 1.3 验证非 Claude Code 的普通搜索结果（App、文件、文件夹等）布局不受影响

## 2. 扩展切换竞态条件修复

- [x] 2.1 在 `SearchPanelViewController+Modes.swift` 的 `handleEnterClaudeCodeModeDirectly()` 方法中，移除 `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)` 延迟包装，改为同步调用 `enterClaudeCodeMode()`
- [x] 2.2 验证通过快捷键进入 ClaudeCode 扩展模式仍然能正常工作（面板显示 + ClaudeCode 内容加载正确）
- [x] 2.3 验证快速连续切换扩展界面（自定义扩展 ↔ ClaudeCode）不再出现界面显示错误
