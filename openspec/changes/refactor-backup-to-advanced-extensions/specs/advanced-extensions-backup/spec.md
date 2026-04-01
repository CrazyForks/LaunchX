## ADDED Requirements

### Requirement: 备份范围仅限高级扩展配置
BackupModel v2.0 SHALL 仅包含高级扩展模块的配置和数据，不包含通用基础设置（窗口模式、全局快捷键等）。

#### Scenario: 导出不包含基础设置
- **WHEN** 用户点击「导出」按钮创建备份
- **THEN** 生成的 JSON 文件中不包含 `generalSettings` 字段，版本号为 "2.0"

#### Scenario: 导入拒绝旧版备份
- **WHEN** 用户尝试导入版本号为 "1.1" 或更早的备份文件
- **THEN** 系统显示错误提示"不支持的备份版本，请使用 v2.0 格式导出的文件"

### Requirement: 导出包含全部 8 个高级扩展模块配置
导出的备份文件 SHALL 包含以下模块的完整配置：
- ClipboardSettings（剪贴板）
- SnippetSettings + Snippet 数据
- AITranslateSettings（AI 翻译）
- BookmarkSettings（书签搜索）
- TwoFactorAuthSettings（2FA 短信）
- TerminalSettings（终端）
- RemindersSettings（提醒事项）
- ClaudeCodeSwitcherSettings（Claude Code）

#### Scenario: 导出文件包含所有模块配置
- **WHEN** 用户点击「导出」按钮
- **THEN** 生成的 JSON 包含上述所有模块的配置字段，每个字段的值反映当前系统实际设置

#### Scenario: 各模块配置独立存储
- **WHEN** 用户导入一个包含部分模块配置的备份文件（未来模块可能增减）
- **THEN** 系统对存在的模块配置进行恢复，不因缺少某个模块字段而失败

### Requirement: 导入/导出按钮位于高级扩展页面
导入/导出按钮 SHALL 位于「高级扩展」页面的左侧扩展列表底部，位于分割线下方。

#### Scenario: 通用设置页不再显示备份按钮
- **WHEN** 用户打开「通用」设置页
- **THEN** 页面中不显示任何配置备份、导入或导出相关的 UI 元素

#### Scenario: 高级扩展页面显示导入导出按钮
- **WHEN** 用户切换到「高级扩展」标签页
- **THEN** 在左侧扩展列表底部、分割线下方，可见「导出配置」和「导入配置」两个按钮

### Requirement: 导入操作需用户确认
导入配置 SHALL 显示确认对话框，明确告知用户将覆盖当前高级扩展的设置。

#### Scenario: 导入前显示确认对话框
- **WHEN** 用户选择备份文件后
- **THEN** 系统弹出确认对话框，提示"导入将覆盖当前所有高级扩展的配置（包括开关、别名、快捷键、自定义数据等），此操作不可撤销"

#### Scenario: 用户取消导入
- **WHEN** 用户在确认对话框中点击「取消」
- **THEN** 不执行任何配置变更

#### Scenario: 导入成功后提示
- **WHEN** 导入成功完成
- **THEN** 系统提示"高级扩展配置已恢复，建议重启 LaunchX 以确保所有功能完全生效"

### Requirement: 导出生成 JSON 文件
导出 SHALL 使用 NSSavePanel 让用户选择保存位置，文件名默认为 `LaunchX_Backup_日期时间.json`。

#### Scenario: 导出文件保存
- **WHEN** 用户点击「导出配置」并选择保存位置
- **THEN** 系统将 BackupModel 编码为格式化的 JSON 并写入指定路径

#### Scenario: 导出成功提示
- **WHEN** 文件写入成功
- **THEN** 系统提示"高级扩展配置已成功备份"

### Requirement: 导入后触发全局刷新
导入完成后 SHALL 发送 `AppConfigDidImport` 通知并重新加载 SnippetService 内存数据。

#### Scenario: Snippet 数据重新加载
- **WHEN** 导入成功完成
- **THEN** SnippetService.shared 调用 reloadAfterImport() 刷新内存中的 snippet 数据

#### Scenario: 全局配置刷新通知
- **WHEN** 导入成功完成
- **THEN** 系统发送 `AppConfigDidImport` 通知，各功能模块监听并重新加载配置
