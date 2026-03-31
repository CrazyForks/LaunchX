## Context

Claude Code Switcher 模块已完成核心功能：通过搜索面板输入别名（默认 "cc"）进入 Provider/MCP/Skills 三组切换模式。模块采用 `@MainActor` 的 Service 层 + SearchPanelViewController 的 UI 层架构。设置界面 `ClaudeCodeSettingsView` 仅包含 Tab 式列表管理，缺少标准扩展设置元素。

现有扩展设置页（Bookmark、2FA）已建立统一的 UI 模式：`SettingsHeaderStyle` 标准头部 + `ExtensionHotKeyButton` / `ExtensionHotKeyRecorderPopover` 快捷键组件 + TextField 别名输入。本设计需复用这些既有组件。

## Goals / Non-Goals

**Goals:**
- 统一前台与设置界面的 Claude Code 图标视觉
- 提升活跃/已启用状态的视觉辨识度（绿色指示）
- 消除 Skills 安装和发现过程中的主线程阻塞
- 补齐用户可配置的别名和快捷键设置入口
- 连接快捷键回调，使全局快捷键可直接打开 Claude Code 模式

**Non-Goals:**
- 不重新设计 Claude Code 模式的整体交互流程
- 不改变 ClaudeCodeSwitcherSettings 的数据模型（保持单一配置而非三组独立配置）
- 不优化 ClaudeDataStore 的 queue.sync 机制（影响较小，不在本次范围）

## Decisions

### D1: 图标统一方案 — 使用 `cpu` SF Symbol

**选择**: 入口图标从 `terminal.fill` 改为 `cpu`
**替代方案**: 嵌入自定义 PNG 图片资源
**理由**: `cpu` 已在 `AdvancedExtensionsView` 侧边栏中使用，视觉一致且无需维护额外资源文件。修改点仅在 `checkClaudeCodeAliasMatch` 方法中的 `NSImage(systemSymbolName:)` 参数。

### D2: 绿色状态图标 — 使用 paletteColors 配置

**选择**: 使用 `NSImage.SymbolConfiguration(paletteColors:)` 为 `checkmark.circle.fill` 设置绿色
**替代方案**: 仅设置 `contentTintColor = .systemGreen`（会使整个图标单色化）
**理由**: `paletteColors` 可分别控制图标的前景色（勾选标记）和背景色（圆圈填充），视觉更精致。推荐使用 `.systemGreen` + `.systemGreen.withAlphaComponent(0.15)` 组合。

选中行时的处理：在 `ResultCellView.configure()` 中检测 Claude Code 活跃项（`isClaudeCodeItem && path == "active"`），选中时设 `contentTintColor = .white`，未选中时设为绿色图标。

**实现位置**: `SearchPanelViewController+Modes.swift` 构建 SearchResult 时传入带绿色配置的图标；`ResultCellView.swift` 的 `configure` 方法中对 Claude Code 活跃项做 tint 处理。

### D3: Skills 网络请求异步化 — URLSession 替代同步 API

**选择**: `String(contentsOf:)` / `Data(contentsOf:)` → `URLSession.shared.data(from:)` 异步版本
**理由**: `@MainActor` 下的 `async/await` 在 `await` 点会自动让出主线程，不阻塞 UI。

**改动范围**:

```
installSkill(_:) throws → installSkill(_:) async throws
├── String(contentsOf: url) → await URLSession.shared.data(from: url)
└── 调用处: try? service.installSkill() → Task { try? await service.installSkill() }

discoverSkills() async 中:
├── Data(contentsOf: contentUrl) → URLSession.shared.data(from: contentUrl)
```

调用链变更:
```
之前: onInstall { try? service.installSkill(); Task { await service.discoverSkills() } }
之后: onInstall { Task { try? await service.installSkill(); await service.discoverSkills() } }
```

### D4: 设置 UI 布局 — 在现有 TabView 上方添加标准设置区域

**选择**: 在 `ClaudeCodeSettingsView` 顶部添加标准扩展设置区域（启用开关、快捷键、别名），下方保留现有 TabView
**替代方案**: 创建独立设置页或 Tab
**理由**: 参照 `BookmarkSearchSettingsView` 的模式，设置项在顶部、功能列表在下方。用户进入 Claude Code 设置页即可同时看到所有配置项，无需额外导航。

布局结构:
```
ScrollView {
  VStack {
    // 标准头部: cpu 图标 + "Claude Code" 标题 + 启用开关
    // 快捷键行: label + ExtensionHotKeyButton + popover
    // 别名行: label + TextField
    Divider()
    // 现有 TabView (Provider / MCP / Skills)
  }
}
```

### D5: 快捷键启动注册 — 在 LanuchXApp 中连接

**改动点**:
1. `LanuchXApp.swift` 的 `applicationDidFinishLaunching` 中添加 `loadClaudeCodeHotKey()` 调用
2. 赋值 `onClaudeCodeHotKeyPressed` 回调，发送 `enterClaudeCodeModeDirectly` 通知并打开搜索面板
3. `HotKeyService.swift` 的 `handleConfigImport()` 中添加 `loadClaudeCodeHotKey()` 调用

回调行为: 发送 `enterClaudeCodeModeDirectly` 通知 → SearchPanelViewController 收到通知后调用 `handleEnterClaudeCodeModeDirectly()` → 直接进入 Claude Code 模式并打开搜索面板。

## Risks / Trade-offs

- **[绿色图标在浅色模式下可见性]** → `systemGreen` 在浅色和深色模式下均有良好对比度，风险低
- **[async installSkill 改变方法签名]** → 调用处只有 SkillListView 一处，影响可控。需要确保错误处理（`try?`）仍然正确展示
- **[discoverSkills 中多个 URL 请求]** → 改为异步后并发行为不变（串行 await），但每个 await 点都不会阻塞主线程
- **[设置 UI 高度增加]** → 顶部新增 3 行设置项，使用 ScrollView 包裹，不影响内容溢出
