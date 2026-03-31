## 1. 图标与颜色优化

- [x] 1.1 SearchPanelViewController+Search.swift: 将 checkClaudeCodeAliasMatch 方法中入口图标从 `terminal.fill` 改为 `cpu`
- [x] 1.2 SearchPanelViewController+Modes.swift: loadClaudeCodeItems 和 filterClaudeCodeItems 中，为活跃项（path == "active"）的 `checkmark.circle.fill` 图标应用绿色 paletteColors 配置（NSColor.systemGreen）
- [x] 1.3 ResultCellView.swift: configure 方法中增加对 Claude Code 活跃项（isClaudeCodeItem && path == "active"）的识别，未选中时设 iconView.contentTintColor = .systemGreen，选中时设为 .white

## 2. Skills 网络请求异步化

- [x] 2.1 ClaudeSkillService.swift: installSkill 方法改为 `async throws`，将 `String(contentsOf: url)` 替换为 `let (data, _) = try await URLSession.shared.data(from: url); let content = String(data: data, encoding: .utf8)`
- [x] 2.2 ClaudeSkillService.swift: discoverSkills 方法中 `Data(contentsOf: contentUrl)` 替换为 `let (data, _) = try await URLSession.shared.data(from: contentUrl)`
- [x] 2.3 SkillListView.swift: onInstall 回调改为 `Task { try? await service.installSkill(discovered); await service.discoverSkills() }`

## 3. 设置 UI 补齐

- [x] 3.1 ClaudeCodeSettingsView.swift: 在现有 TabView 上方添加标准设置头部（cpu 图标 + "Claude Code" 标题 + 启用开关），遵循 SettingsHeaderStyle
- [x] 3.2 ClaudeCodeSettingsView.swift: 添加 "直接打开快捷键:" 行，使用 ExtensionHotKeyButton + ExtensionHotKeyRecorderPopover，exampleKey 为 "C"
- [x] 3.3 ClaudeCodeSettingsView.swift: 添加 "别名:" 行，使用 TextField(.roundedBorder, width: 80)，onChange 时调用 settings.save()
- [x] 3.4 ClaudeCodeSettingsView.swift: 引入 @StateObject 或 @ObservedObject 绑定 ClaudeCodeSwitcherSettings，确保 isEnabled、alias、hotKeyCode、hotKeyModifiers 双向绑定

## 4. 快捷键功能连接

- [x] 4.1 LanuchXApp.swift: 在 applicationDidFinishLaunching 中添加 loadClaudeCodeHotKey() 调用（与其他 loadXxxHotKey 并列）
- [x] 4.2 LanuchXApp.swift: 赋值 onClaudeCodeHotKeyPressed 回调，发送 enterClaudeCodeModeDirectly 通知并打开搜索面板
- [x] 4.3 HotKeyService.swift: 在 handleConfigImport 方法中添加 loadClaudeCodeHotKey() 调用
