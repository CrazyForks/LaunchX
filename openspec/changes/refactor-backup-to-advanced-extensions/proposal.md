## Why

当前的导入/导出功能放在「通用」设置页中，导出内容混杂了基础设置（窗口模式、全局快捷键）和部分高级扩展配置。实际上用户真正需要备份和迁移的是所有高级扩展模块的个性化配置（开关、别名、快捷键、自定义数据等），而不是通用基础设置。将导入/导出按钮移至「高级扩展」模块中，能让功能定位更清晰，也方便用户在高级扩展界面统一管理自己的定制化数据。

## What Changes

- **移除**「通用」设置页中的「配置备份」区域（导入/导出按钮）
- **新增**「高级扩展」视图中的导入/导出功能入口，放在左侧扩展列表底部或右侧面板顶部
- **重构 BackupModel**：移除 `generalSettings`（基础设置），改为包含所有 8 个高级扩展模块的配置：
  - `ClipboardSettings`（剪贴板：开关、别名、快捷键等）
  - `SnippetSettings` + `[SnippetItem]`（Snippet 开关、别名、自定义 snippet 数据）
  - `AITranslateSettings`（AI 翻译：开关、别名、快捷键、模型配置等）
  - `BookmarkSettings`（书签搜索：开关、别名、快捷键、打开方式等）
  - `TwoFactorAuthSettings`（2FA 短信：开关、别名、快捷键等）
  - `TerminalSettings`（终端选择）
  - `RemindersSettings`（提醒事项开关）
  - `ClaudeCodeSwitcherSettings`（Claude Code：开关、别名、快捷键等）
- **更新 BackupService**：导入/导出仅处理高级扩展相关配置
- 更新版本号为 "2.0"（因备份格式不兼容）

## Capabilities

### New Capabilities
- `advanced-extensions-backup`: 高级扩展配置的完整导入/导出功能，覆盖全部 8 个模块的设置和数据

### Modified Capabilities

## Impact

- **BackupModel.swift**：数据模型重构，移除 `GeneralSettings`，新增所有高级模块配置字段
- **BackupService.swift**：更新 `exportConfiguration` / `importConfiguration` 的确认提示文案
- **SettingsView.swift**（GeneralSettingsView）：移除配置备份 UI 区域
- **AdvancedExtensionsView.swift**：新增导入/导出按钮 UI
- **各模块 Settings 模型**：无需修改（已支持 Codable 和 load/save）
- **向后兼容**：备份格式从 v1.1 变为 v2.0，旧版备份文件将无法直接导入（**BREAKING**）

### 回滚计划
- 保留 `GeneralSettings` 结构定义但标记为可选，以便将来需要时恢复
- Git 中保留旧版代码，可随时回退
