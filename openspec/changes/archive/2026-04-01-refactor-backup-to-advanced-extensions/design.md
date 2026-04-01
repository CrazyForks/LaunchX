## Context

当前 LaunchX 的导入/导出功能位于「通用」设置页，导出内容包含基础设置（窗口模式、全局快捷键）和少量高级扩展配置（Snippet、AI 翻译）。但用户真正需要备份和迁移的是所有高级扩展模块的个性化配置。备份模型 `BackupModel` 当前只包含 `GeneralSettings`、`SnippetSettings`/`[SnippetItem]` 和 `AITranslateSettings`，缺少剪贴板、书签搜索、2FA、终端、提醒事项、Claude Code 等 5 个模块的配置。

所有高级模块的设置模型已遵循统一的 `Codable` + `load()/save()` 模式，这为全面备份提供了良好的基础。

## Goals / Non-Goals

**Goals:**
- 将导入/导出功能从「通用」设置页移至「高级扩展」页面
- 备份覆盖全部 8 个高级扩展模块的配置和数据
- 移除基础设置（窗口模式、全局快捷键）的备份
- UI 设计与现有高级扩展界面风格保持一致

**Non-Goals:**
- 不支持旧版备份文件的自动迁移（v1.x → v2.0）
- 不改变各模块自身的设置模型结构
- 不添加备份历史或自动备份功能

## Decisions

### 1. 导入/导出按钮放置位置

**决策**：在 `AdvancedExtensionsView` 的左侧扩展列表底部添加导入/导出按钮区域，与列表之间用分割线隔开。

**理由**：
- 左侧列表是用户进入高级扩展页面的第一视觉焦点
- 放在底部不干扰扩展选择操作，但仍然一目了然
- 右侧面板内容随选择切换而变化，不适合放置全局操作按钮

**备选方案**：
- 放在右侧面板顶部：会随模块切换而变化，不够稳定
- 独立为一个虚拟"扩展"项（如"配置管理"）：增加列表复杂度，且不是真正的扩展

### 2. BackupModel 数据结构重构

**决策**：使用扁平结构，每个模块一个顶层字段。

```
BackupModel v2.0
├── metadata (version: "2.0", exportDate, appVersion, deviceName)
├── clipboardSettings: ClipboardSettings
├── snippetSettings: SnippetSettings
├── snippets: [SnippetItem]
├── aiTranslateSettings: AITranslateSettings
├── bookmarkSettings: BookmarkSettings
├── twoFactorAuthSettings: TwoFactorAuthSettings
├── terminalSettings: TerminalSettings
├── remindersSettings: RemindersSettings
└── claudeCodeSwitcherSettings: ClaudeCodeSwitcherSettings
```

**理由**：与现有模式一致（各模块 Settings 已 Codable），无需引入嵌套层次。

### 3. 版本号策略

**决策**：将备份版本从 "1.1" 升级到 "2.0"，导入时校验版本号，拒绝 v1.x 备份文件。

**理由**：备份格式不兼容（移除了 generalSettings，新增了多个模块配置），需要明确告知用户。简单的版本校验比复杂的向后兼容迁移更可靠。

### 4. apply() 恢复策略

**决策**：`apply()` 按模块逐一调用各 Settings 的 `save()` 方法，Snippet 数据写入文件系统，最后发送全局通知 `AppConfigDidImport`。

**理由**：复用各模块已有的 `save()` 方法，避免重复实现存储逻辑。

## Risks / Trade-offs

- **[向后不兼容]** v1.x 备份文件无法导入 → 导入时给出清晰的错误提示"不支持的备份版本，请使用 v2.0 格式"
- **[备份文件体积]** 包含 Snippet 数据可能较大 → JSON 格式本身较紧凑，且 Snippet 数据量通常有限
- **[模块新增]** 未来新增高级扩展模块时需同步更新 BackupModel → 在 BackupModel 中添加注释提醒开发者
