## Why

LaunchX 已完整集成了 Claude Code 的配置管理功能（Provider/MCP/Skills），但 OpenAI Codex CLI 作为另一个主流的 AI 编程工具，同样拥有 Provider 切换、MCP Server 管理、Skills 管理等能力。用户需要在 LaunchX 中也能方便地管理 Codex CLI 的配置，实现与 Claude Code 对等的功能体验。现在做是因为 Codex CLI 已开源且功能成熟，用户群体在快速增长。

## What Changes

- 新增 Codex CLI 配置管理模块，支持 Provider 切换（包括 OpenAI 官方、自定义 Provider、Ollama/LMStudio 等本地模型）
- 新增 Codex MCP Server 管理功能，支持 STDIO 和 Streamable HTTP 两种传输方式的 MCP 服务器 CRUD 和启用/禁用
- 新增 Codex Skills 管理功能，支持从 GitHub 仓库发现、安装、启用/禁用 Skills
- 在搜索面板中集成 Codex 模式（类似 `cc` 别名进入 Claude Code Switcher），通过 `cx` 别名进入 Codex Switcher
- 新增 Codex 相关的设置界面（Provider/MCP/Skills 三栏管理）
- 新增 Provider 预设（OpenAI 官方、Azure、各类代理/中转站等 20+ 内置预设）
- 新增全局快捷键支持，可直接唤起 Codex Switcher 面板

## Capabilities

### New Capabilities
- `codex-provider-management`: Codex CLI Provider 配置管理，包括 Provider CRUD、预设、激活切换，配置写入 `~/.codex/config.toml`
- `codex-mcp-management`: Codex CLI MCP Server 管理，支持 STDIO 和 Streamable HTTP 类型，配置读写 `~/.codex/config.toml` 的 `[mcp_servers]` 段
- `codex-skills-management`: Codex CLI Skills 管理，支持从 GitHub 仓库发现和安装 Skills，本地存储到 `~/Library/Application Support/LaunchX/codex/skills/`，创建符号链接到 `~/.agents/skills/`
- `codex-search-panel-integration`: 搜索面板集成 Codex Switcher 模式，包括别名匹配、模式进入/退出、分组展示和操作响应

### Modified Capabilities
- `claude-provider-management`: SearchResult 模型需要扩展 Codex 相关字段（或新增通用的工具类型标识），HotKeyService 需要支持注册 Codex 专用的全局快捷键
- `shared-ui-components`: 设置界面需要新增 Codex 设置入口，可能需要复用或扩展现有的 Provider/MCP/Skills UI 组件

## Impact

- **新增代码**: `Models/CodexProvider*.swift`, `Models/CodexSkill.swift`, `Services/Features/CodexCLI/`, `Views/CodexSettings/`
- **修改代码**: `SearchResult.swift`（新增 Codex 相关字段）、`SearchPanelViewController+Modes.swift`（新增 Codex 模式）、`HotKeyService+CustomHotKeys.swift`（新增 Codex 快捷键）、`SettingsView.swift`（新增 Codex 设置入口）
- **配置文件**: 读写 `~/.codex/config.toml`（TOML 格式，需要引入 TOML 解析/生成库）、读取 `~/.codex/auth.json`
- **数据存储**: `~/Library/Application Support/LaunchX/codex/` 目录下的 JSON 文件（providers, mcp_servers, skills）
- **回滚计划**: 所有 Codex 功能为独立模块，可通过开关禁用。配置文件操作前会备份原始 `~/.codex/config.toml`，最多保留 10 份备份。卸载时删除 `~/Library/Application Support/LaunchX/codex/` 目录即可完全清理。
