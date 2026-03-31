## Why

Claude Code Switcher 模块的核心功能已可用（通过搜索面板输入别名切换 Provider/MCP/Skills），但存在三类问题影响用户体验：1) 前台图标与设置界面不一致；2) 状态指示颜色不够直观；3) Skills 安装时因同步网络请求导致主线程阻塞（彩虹转圈）。此外，别名设置和全局快捷键功能的底层代码已就绪但缺少设置 UI 和启动注册，用户无法自定义配置。

## What Changes

- **图标统一**: 搜索面板 Claude Code 入口图标从 `terminal.fill` 改为 `cpu`，与设置界面侧边栏保持一致
- **状态图标颜色优化**: 已启用/当前项的 `checkmark.circle.fill` 图标改为绿色（选中行时回退白色），提升视觉辨识度
- **性能修复**: `ClaudeSkillService` 中 `installSkill` 和 `discoverSkills` 的同步网络调用（`String(contentsOf:)` / `Data(contentsOf:)`）替换为 `URLSession.shared.data(from:)` 异步版本，消除主线程阻塞
- **补齐别名设置 UI**: 在 `ClaudeCodeSettingsView` 中添加启用开关、别名输入框（复用现有 TextField + `.roundedBorder` 模式）
- **补齐快捷键功能**: 在 `ClaudeCodeSettingsView` 中添加快捷键录制器（复用 `ExtensionHotKeyButton` + `ExtensionHotKeyRecorderPopover`），在 `LanuchXApp.swift` 启动时调用 `loadClaudeCodeHotKey()`，连接 `onClaudeCodeHotKeyPressed` 回调

## Capabilities

### New Capabilities
- `claude-switcher-settings-ui`: Claude Code Switcher 的设置界面，包含启用开关、别名输入框和快捷键录制器

### Modified Capabilities
- `shared-ui-components`: ResultCellView 需要支持对 Claude Code 活跃项图标设置绿色 tint，并在选中行时回退为白色
- `claude-skills-management`: installSkill 和 discoverSkills 方法需从同步网络 API 改为异步 URLSession

## Impact

- **SearchPanelViewController+Search.swift**: 入口图标替换
- **SearchPanelViewController+Modes.swift**: loadClaudeCodeItems / filterClaudeCodeItems 中活跃项图标改为绿色
- **ResultCellView.swift**: configure 方法需识别 Claude Code 活跃项并设置绿色 contentTintColor
- **ClaudeSkillService.swift**: installSkill 改为 async，discoverSkills 中同步调用替换为异步
- **SkillListView.swift**: onInstall 回调改为 async 调用
- **ClaudeCodeSettingsView.swift**: 添加标准设置头部（启用开关）、别名输入行、快捷键录制行
- **LanuchXApp.swift**: 启动时调用 loadClaudeCodeHotKey()，赋值 onClaudeCodeHotKeyPressed 回调
- **HotKeyService.swift**: handleConfigImport 中调用 loadClaudeCodeHotKey()

### Rollback Plan

所有改动局限于 Claude Code 模块内部和设置 UI，不影响其他扩展功能。如需回滚，恢复改动文件即可。性能修复和 UI 优化均为增量改动，不涉及数据模型变更。
