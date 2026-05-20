## ADDED Requirements

### Requirement: Codex Switcher 别名入口
系统 SHALL 支持通过搜索面板别名进入 Codex Switcher 模式。默认别名为 `cx`。用户在搜索面板输入 `cx` 后进入 Codex Switcher 模式，显示分组列表（Provider / MCP / Skills 三个分组，每组显示标题头和对应条目）。

#### Scenario: 通过别名进入 Codex Switcher
- **WHEN** 用户在搜索面板输入 "cx" 并确认
- **THEN** 搜索面板切换到 Codex Switcher 模式，显示 Provider/MCP/Skills 分组列表

#### Scenario: 自定义别名
- **WHEN** 用户将 Codex Switcher 别名改为 "codex"
- **THEN** 输入 "codex" 才能进入 Codex Switcher 模式，"cx" 不再触发

### Requirement: Codex Switcher 模式搜索过滤
系统 SHALL 在 Codex Switcher 模式下支持搜索过滤：用户输入关键词后，在 Provider/MCP/Skills 条目中过滤匹配的条目，保持分组结构。

#### Scenario: 过滤 Provider
- **WHEN** 用户在 Codex Switcher 模式下输入 "open"
- **THEN** 列表只显示名称包含 "open" 的 Provider/MCP/Skills 条目，空分组自动隐藏

### Requirement: Codex Switcher 模式操作响应
系统 SHALL 支持以下操作：Enter 键在 Provider 条目上切换激活该 Provider；Enter 键在 MCP Server 条目上切换启用/禁用；Enter 键在 Skill 条目上切换启用/禁用。操作完成后列表项的图标和状态标签即时更新。

#### Scenario: 切换 Provider
- **WHEN** 用户在 Codex Switcher 模式下选中一个 Provider 条目并按 Enter
- **THEN** 系统激活该 Provider（写入 config.toml），列表中 Provider 条目的图标和状态标签立即更新

#### Scenario: 切换 MCP Server 启用状态
- **WHEN** 用户在 Codex Switcher 模式下选中一个 MCP Server 条目并按 Enter
- **THEN** 系统切换该 Server 的启用/禁用状态，列表项状态立即更新

#### Scenario: 切换 Skill 启用状态
- **WHEN** 用户在 Codex Switcher 模式下选中一个 Skill 条目并按 Enter
- **THEN** 系统切换该 Skill 的启用/禁用状态，列表项状态立即更新

### Requirement: Codex Switcher 模式退出
系统 SHALL 支持通过 Escape 键退出 Codex Switcher 模式，返回普通搜索模式。

#### Scenario: Escape 退出
- **WHEN** 用户在 Codex Switcher 模式下按 Escape
- **THEN** 搜索面板退出 Codex Switcher 模式，清空输入，返回普通搜索

### Requirement: Codex Switcher 全局快捷键
系统 SHALL 支持配置全局快捷键，按下后直接打开搜索面板并进入 Codex Switcher 模式。快捷键可通过设置界面录制。

#### Scenario: 通过快捷键进入
- **WHEN** 用户按下配置的 Codex Switcher 全局快捷键
- **THEN** 搜索面板打开并直接进入 Codex Switcher 模式

#### Scenario: 未配置快捷键
- **WHEN** 用户未配置 Codex Switcher 快捷键
- **THEN** 快捷键功能不注册，不影响其他功能

### Requirement: Codex Switcher 设置界面
系统 SHALL 提供设置界面，包含：启用/禁用开关、别名配置（默认 "cx"）、全局快捷键录制。设置界面可从主设置页面的 Codex 入口访问。

#### Scenario: 禁用 Codex Switcher
- **WHEN** 用户在设置中禁用 Codex Switcher
- **THEN** 别名和快捷键均不再触发 Codex Switcher 模式

#### Scenario: 修改别名
- **WHEN** 用户将别名从 "cx" 改为 "codex"
- **THEN** 新别名立即生效，旧别名不再触发

### Requirement: Codex 设置管理界面
系统 SHALL 提供 Codex CLI 配置管理界面，包含三个标签页：Provider（Provider 列表、添加/编辑表单、预设选择器）、MCP（MCP Server 列表、添加/编辑表单）、Skills（已安装 Skills 列表、发现新 Skills、仓库管理）。

#### Scenario: Provider 标签页
- **WHEN** 用户切换到 Provider 标签页
- **THEN** 显示所有 Provider 列表，当前激活的 Provider 有明显标识，支持添加/编辑/删除/切换操作

#### Scenario: MCP 标签页
- **WHEN** 用户切换到 MCP 标签页
- **THEN** 显示所有 MCP Server 列表，支持添加/编辑/删除/启用禁用操作

#### Scenario: Skills 标签页
- **WHEN** 用户切换到 Skills 标签页
- **THEN** 显示已安装的 Skills 列表，提供发现新 Skills 的入口，支持启用/禁用/卸载操作
