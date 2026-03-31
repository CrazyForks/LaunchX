## ADDED Requirements

### Requirement: Claude Code Switcher 入口别名匹配
系统 SHALL 在用户输入匹配 Claude Code Switcher 配置别名的关键词时，在搜索结果中显示 Claude Code Switcher 入口项。入口项 SHALL 显示 Claude Code 图标和名称"Claude Code"，并附带配置的别名作为 `displayAlias`。

#### Scenario: 别名完全匹配
- **WHEN** 用户输入与配置别名完全匹配的关键词（如 `cc`）
- **THEN** 搜索结果中显示 Claude Code Switcher 入口项，排在结果列表最前面

#### Scenario: 别名前缀匹配
- **WHEN** 用户输入配置别名的前缀（如输入 `c` 匹配别名 `cc`）
- **THEN** 搜索结果中显示 Claude Code Switcher 入口项

#### Scenario: 功能未启用
- **WHEN** Claude Code Switcher 功能未启用（设置中关闭）
- **THEN** 别名匹配不生效，不显示入口项

### Requirement: 通过别名进入 Claude Code Switcher 模式
系统 SHALL 在用户选中 Claude Code Switcher 入口项并按回车后，进入 Claude Code Switcher 扩展模式。

#### Scenario: 选中入口项进入模式
- **WHEN** 用户选中搜索结果中的 Claude Code Switcher 入口项并按回车
- **THEN** 系统进入 Claude Code Switcher 扩展模式，显示 Tag View 标签（图标 + "Claude Code" 文字），搜索框 placeholder 变为"搜索 Provider/MCP/Skills..."，搜索框清空

#### Scenario: 模式内 Escape 退出
- **WHEN** 用户在 Claude Code Switcher 模式中按 Escape 键
- **THEN** 系统退出 Claude Code Switcher 模式，恢复普通搜索状态

### Requirement: 通过快捷键直接进入模式
系统 SHALL 支持配置全局快捷键，按下后直接打开搜索面板并进入 Claude Code Switcher 模式。

#### Scenario: 快捷键触发
- **WHEN** 用户按下配置的 Claude Code Switcher 全局快捷键
- **THEN** 搜索面板打开并直接进入 Claude Code Switcher 模式

#### Scenario: 已在其他扩展模式中
- **WHEN** 用户在其他扩展模式中按下 Claude Code Switcher 快捷键
- **THEN** 系统先清理当前扩展模式，再进入 Claude Code Switcher 模式

### Requirement: 模式内显示 Provider/MCP/Skills 列表
系统 SHALL 在 Claude Code Switcher 模式中按分组显示 Provider、MCP 服务器、Skills 三个列表。

#### Scenario: 加载并显示列表
- **WHEN** 进入 Claude Code Switcher 模式
- **THEN** 系统从 `ClaudeProviderService`、`ClaudeMcpService`、`ClaudeSkillService` 加载数据
- **THEN** 搜索结果分为三个分组：Provider、MCP 服务器、Skills，每组以分组标题开头
- **THEN** Provider 列表中每项显示名称和类别，当前激活的 Provider 项带有标记
- **THEN** MCP 服务器列表中每项显示名称和启用状态
- **THEN** Skills 列表中每项显示名称和启用状态

#### Scenario: 列表为空
- **WHEN** 某个分类（如 Skills）没有数据
- **THEN** 该分类不显示（包括分组标题也不显示）

### Requirement: 模式内搜索过滤
系统 SHALL 支持在 Claude Code Switcher 模式中输入关键词搜索过滤列表项。

#### Scenario: 关键词过滤
- **WHEN** 用户在 Claude Code Switcher 模式中输入关键词
- **THEN** 系统过滤三个分类中的项，只显示名称包含关键词的项
- **THEN** 如果某个分类过滤后没有匹配项，该分类及其分组标题不显示

#### Scenario: 清空搜索恢复全部
- **WHEN** 用户清空搜索框内容
- **THEN** 恢复显示所有 Provider/MCP/Skills 列表

### Requirement: 切换 Provider
系统 SHALL 支持在 Claude Code Switcher 模式中选中 Provider 并按回车切换。

#### Scenario: 切换到其他 Provider
- **WHEN** 用户选中一个非当前激活的 Provider 并按回车
- **THEN** 系统调用 `ClaudeProviderService.switchProvider(to:)` 执行切换
- **THEN** 切换完成后刷新列表，新 Provider 显示为激活状态
- **THEN** 显示 HUD 提示"已切换到 {Provider 名称}"

#### Scenario: 选中当前已激活的 Provider
- **WHEN** 用户选中当前已激活的 Provider 并按回车
- **THEN** 不执行任何操作

#### Scenario: 切换失败
- **WHEN** Provider 切换过程中发生错误
- **THEN** 显示 HUD 错误提示，列表保持不变

### Requirement: 切换 MCP 服务器启用状态
系统 SHALL 支持在 Claude Code Switcher 模式中选中 MCP 服务器按回车切换启用/禁用。

#### Scenario: 禁用已启用的 MCP 服务器
- **WHEN** 用户选中一个已启用的 MCP 服务器并按回车
- **THEN** 系统调用 `ClaudeMcpService` 禁用该 MCP 服务器并同步到 Claude Code 配置
- **THEN** 列表中该项状态更新为禁用

#### Scenario: 启用已禁用的 MCP 服务器
- **WHEN** 用户选中一个已禁用的 MCP 服务器并按回车
- **THEN** 系统调用 `ClaudeMcpService` 启用该 MCP 服务器并同步到 Claude Code 配置
- **THEN** 列表中该项状态更新为启用

### Requirement: 切换 Skill 启用状态
系统 SHALL 支持在 Claude Code Switcher 模式中选中 Skill 按回车切换启用/禁用。

#### Scenario: 禁用已启用的 Skill
- **WHEN** 用户选中一个已启用的 Skill 并按回车
- **THEN** 系统调用 `ClaudeSkillService` 禁用该 Skill
- **THEN** 列表中该项状态更新为禁用

#### Scenario: 启用已禁用的 Skill
- **WHEN** 用户选中一个已禁用的 Skill 并按回车
- **THEN** 系统调用 `ClaudeSkillService` 启用该 Skill
- **THEN** 列表中该项状态更新为启用

### Requirement: 别名和快捷键配置
系统 SHALL 在别名/快捷键设置界面中提供 Claude Code Switcher 的配置项。

#### Scenario: 配置别名
- **WHEN** 用户在设置中为 Claude Code Switcher 设置别名（如 `cc`）
- **THEN** 后续在搜索面板中输入该别名即可触发入口匹配

#### Scenario: 启用/禁用功能
- **WHEN** 用户在设置中启用或禁用 Claude Code Switcher
- **THEN** 启用后别名匹配和快捷键生效，禁用后均不生效
