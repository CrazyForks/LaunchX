## ADDED Requirements

### Requirement: Claude Code Switcher 设置头部
ClaudeCodeSettingsView 顶部 SHALL 包含标准扩展设置头部，遵循 SettingsHeaderStyle 规范。

#### Scenario: 标准头部显示
- **WHEN** 用户打开 Claude Code 设置页面
- **THEN** 页面顶部显示 `cpu` 图标（棕色）+ "Claude Code" 标题 + 启用/禁用开关，符合 SettingsHeaderStyle 统一样式

#### Scenario: 启用开关切换
- **WHEN** 用户切换启用开关
- **THEN** ClaudeCodeSwitcherSettings 的 isEnabled 字段更新并持久化，搜索面板立即响应（关闭后不再匹配别名）

### Requirement: Claude Code 别名设置
ClaudeCodeSettingsView SHALL 提供别名输入框，允许用户自定义搜索面板匹配别名。

#### Scenario: 别名输入框显示
- **WHEN** 用户打开 Claude Code 设置页面
- **THEN** 在头部下方显示 "别名:" 标签 + TextField（.roundedBorder 样式，宽度 80），占位符为 "cc"

#### Scenario: 修改别名
- **WHEN** 用户在别名输入框中输入新值
- **THEN** ClaudeCodeSwitcherSettings.alias 更新并持久化，搜索面板立即使用新别名匹配

#### Scenario: 清空别名
- **WHEN** 用户将别名输入框清空
- **THEN** Claude Code 入口不再出现在搜索结果中（alias 为空时不匹配）

### Requirement: Claude Code 快捷键设置
ClaudeCodeSettingsView SHALL 提供快捷键录制器，允许用户配置全局快捷键直接打开 Claude Code Switcher 模式。

#### Scenario: 快捷键录制器显示
- **WHEN** 用户打开 Claude Code 设置页面
- **THEN** 在别名行上方显示 "直接打开快捷键:" 标签 + ExtensionHotKeyButton

#### Scenario: 录制快捷键
- **WHEN** 用户点击快捷键按钮并在弹窗中录制新快捷键
- **THEN** 系统注册新全局快捷键，注销旧快捷键，持久化 keyCode 和 modifiers

#### Scenario: 快捷键冲突检测
- **WHEN** 用户录制的快捷键与已有快捷键冲突
- **THEN** 弹窗显示冲突信息，阻止注册

#### Scenario: 清除快捷键
- **WHEN** 用户在弹窗中按 Delete/Backspace
- **THEN** 快捷键清除（keyCode 和 modifiers 设为 0），注销全局快捷键

### Requirement: 快捷键启动注册
应用启动时 SHALL 加载并注册 Claude Code 快捷键。

#### Scenario: 应用启动时注册快捷键
- **WHEN** 应用启动完成（applicationDidFinishLaunching）
- **THEN** 系统调用 loadClaudeCodeHotKey()，读取 ClaudeCodeSwitcherSettings 中的 hotKeyCode/hotKeyModifiers 并注册全局快捷键

#### Scenario: 配置导入后注册快捷键
- **WHEN** 用户导入配置（handleConfigImport）
- **THEN** 系统调用 loadClaudeCodeHotKey() 重新注册快捷键

### Requirement: 快捷键回调连接
全局快捷键按下时 SHALL 直接打开搜索面板并进入 Claude Code 模式。

#### Scenario: 按下快捷键
- **WHEN** 用户按下已注册的 Claude Code 全局快捷键
- **THEN** 系统发送 enterClaudeCodeModeDirectly 通知，SearchPanelViewController 收到通知后打开搜索面板并直接进入 Claude Code 模式

### Requirement: Claude Code 入口图标统一
搜索面板中 Claude Code 入口的图标 SHALL 与设置界面保持一致。

#### Scenario: 入口图标使用 cpu
- **WHEN** 搜索面板通过别名匹配显示 Claude Code 入口
- **THEN** 入口图标使用 `cpu` SF Symbol（与 AdvancedExtensionsView 侧边栏一致）
