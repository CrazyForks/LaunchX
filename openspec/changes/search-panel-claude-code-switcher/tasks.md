## 1. 数据模型与配置

- [ ] 1.1 在 SearchResult 中新增 `isClaudeCodeEntry`、`isClaudeCodeItem`、`claudeCodeItemType`（枚举：provider/mcp/skill）、`claudeCodeItemId`（UUID）字段及对应的 init 参数
- [ ] 1.2 创建 `ClaudeCodeSwitcherSettings` 配置模型（包含 isEnabled、alias、hotKey 字段），支持 `load()` / `save()` 持久化到 UserDefaults
- [ ] 1.3 更新 `isInAnyExtensionMode` 计算属性，加入 `isInClaudeCodeMode` 判断

## 2. 搜索面板模式逻辑

- [ ] 2.1 在 `SearchPanelViewController+Search.swift` 中新增 `checkClaudeCodeAliasMatch(query:)` 方法，检测别名匹配并返回 Claude Code Switcher 入口 SearchResult
- [ ] 2.2 在 `performSearch` 方法中调用 `checkClaudeCodeAliasMatch`，将入口项插入搜索结果
- [ ] 2.3 在 `SearchPanelViewController.swift` 中新增 `isInClaudeCodeMode: Bool` 状态属性和 `currentClaudeCodeItems` 缓存属性
- [ ] 2.4 在 `SearchPanelViewController+Modes.swift` 中实现 `enterClaudeCodeMode()` 方法：设置模式状态、更新 UI、加载数据
- [ ] 2.5 在 `SearchPanelViewController+Modes.swift` 中实现 `updateClaudeCodeModeUI()` 方法：显示 Tag View（Claude Code 图标 + "Claude Code" 文字）、设置 placeholder、清空搜索框
- [ ] 2.6 在 `SearchPanelViewController+Modes.swift` 中实现 `loadClaudeCodeItems()` 方法：从三个 Service 加载数据，构建带分组标题的 results 数组
- [ ] 2.7 在 `SearchPanelViewController+Modes.swift` 中实现 `filterClaudeCodeItems(query:)` 方法：根据关键词过滤当前缓存的列表项
- [ ] 2.8 在 `SearchPanelViewController+Modes.swift` 中实现 `handleClaudeCodeItemSelected()` 方法：根据 `claudeCodeItemType` 调用对应 Service 的切换/启用/禁用方法
- [ ] 2.9 在 `cleanupAllExtensionModes` 中加入 Claude Code 模式的清理逻辑
- [ ] 2.10 在 `SearchPanelViewController+Delegates.swift` 的 `tableViewSelectionDidChange` 或回车处理中，识别 Claude Code 入口项和子项，调用对应的模式进入或切换方法

## 3. 快捷键支持

- [ ] 3.1 在 `CustomItemsConfig.swift` 中新增 `enterClaudeCodeModeDirectly` 通知名
- [ ] 3.2 在 `SearchPanelViewController+Modes.swift` 中实现 `handleEnterClaudeCodeModeDirectly` 通知处理方法
- [ ] 3.3 在 `SearchPanelViewController.swift` 的 `viewDidLoad` 或 `setupNotificationObservers` 中注册 `enterClaudeCodeModeDirectly` 通知监听
- [ ] 3.4 在 `HotKeyService+CustomHotKeys.swift` 中新增 Claude Code Switcher 快捷键注册方法 `registerClaudeCodeSwitcherHotKey()`
- [ ] 3.5 在 `HotKeyService` 主文件中调用快捷键注册

## 4. 设置界面

- [ ] 4.1 在别名/快捷键设置界面中新增 Claude Code Switcher 配置项（启用开关、别名输入框、快捷键设置）
- [ ] 4.2 在 `AdvancedExtensionsView.swift` 中确保 Claude Code 扩展配置正确引用新的设置模型

## 5. 集成与验证

- [ ] 5.1 在 `SearchPanelViewController+Search.swift` 的 `performSearch` 方法中集成别名匹配，确保空搜索时也能正确返回入口项
- [ ] 5.2 验证模式内搜索过滤功能正常工作
- [ ] 5.3 验证 Provider 切换后列表正确刷新
- [ ] 5.4 验证 MCP/Skills 启用/禁用切换后列表正确刷新
- [ ] 5.5 验证 Escape 退出模式和模式间切换的清理逻辑
- [ ] 5.6 编译项目确保无错误
