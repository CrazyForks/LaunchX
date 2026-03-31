## Why

Provider/MCP/Skills 的切换功能目前只在设置界面中可用，用户需要先打开设置才能切换。这不符合 LaunchX 作为效率工具的定位——其他扩展功能（书签、2FA、实用工具等）都已在搜索面板中通过别名或快捷键直接访问。将 Claude Code 切换功能集成到搜索面板中，可以让用户无需离开当前工作流即可快速切换 Provider、启用/禁用 MCP 服务器和 Skills。

## What Changes

- 新增三个独立的搜索面板扩展模式入口：Provider Switcher、MCP Switcher、Skills Switcher
- 每个入口有各自配置的别名（如 `ccp` 进入 Provider、`mcp` 进入 MCP、`skill` 进入 Skills），用户输入别名匹配后选中进入
- 各模式内显示对应的列表（Provider / MCP 服务器 / Skills），支持搜索过滤
- 选中后按回车执行操作：Provider 切换 / MCP 启用禁用 / Skills 启用禁用
- 各入口支持独立的全局快捷键直接进入
- 在别名/快捷键设置中新增三个入口各自的别名和快捷键配置项
- 复用现有的 `ClaudeProviderService`、`ClaudeMcpService`、`ClaudeSkillService` 服务层

## Capabilities

### New Capabilities
- `claude-code-switcher`: 搜索面板中的 Claude Code 快速切换扩展模式，Provider/MCP/Skills 各自拥有独立的别名入口和快捷键，分别进入各自的列表模式并执行切换/启用/禁用操作

### Modified Capabilities
（无现有 spec 的需求变更，仅新增搜索面板交互层，底层服务层保持不变）

## Impact

- **SearchResult 模型**: 新增 `isClaudeCodeEntry` 和 `isClaudeCodeItem` 字段，以及 `claudeCodeItemType` 枚举区分 provider/mcp/skill
- **SearchPanelViewController**: 新增 `isInClaudeCodeMode` 模式状态及 `claudeCodeModeType` 子类型
- **SearchPanelViewController+Search.swift**: 新增 `checkClaudeProviderAliasMatch`、`checkClaudeMcpAliasMatch`、`checkClaudeSkillAliasMatch` 三个独立别名匹配方法
- **SearchPanelViewController+Modes.swift**: 新增 `enterClaudeCodeMode(type:)`、`loadClaudeCodeItems(type:)`、`filterClaudeCodeItems(query:)` 等方法
- **CustomItemsConfig.swift**: 新增三个 `enterClaudeXxxModeDirectly` 通知
- **HotKeyService**: 新增三个快捷键注册
- **别名/快捷键设置界面**: 新增 Provider/MCP/Skills 三个独立配置项
