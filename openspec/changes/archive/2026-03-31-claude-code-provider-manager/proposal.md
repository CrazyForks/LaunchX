## Why

LaunchX 是一款 macOS 启动器应用，目前缺少对 Claude Code CLI 工具的管理能力。用户在使用 Claude Code 时，切换 API Provider、管理 MCP 服务器和安装 Skills 都需要手动编辑 JSON 配置文件，体验较差。参考 cc-switch 项目的 Claude Code 相关功能，将这些能力集成到 LaunchX 中，可以让用户在启动器中一站式管理 Claude Code 的 Provider、MCP 和 Skills 配置，无需额外安装独立工具。

## What Changes

- **新增 Provider 管理**：支持添加、编辑、删除、切换 Claude Code 的 API Provider，包括 20+ 内置预设（官方、第三方、聚合平台、云服务商等），一键切换后自动写入 `~/.claude/settings.json`
- **新增 MCP 服务器管理**：统一管理 Claude Code 的 MCP 服务器配置，支持添加/编辑/删除/启用禁用，自动同步到 `~/.claude.json` 的 `mcpServers` 区段
- **新增 Skills 管理**：从 GitHub 仓库发现和安装 Claude Code Skills，支持 symlink 同步到 `~/.claude/skills/` 目录，支持导入已有 Skills
- **新增 Provider 预设系统**：内置常用 Provider 预设（官方登录、OpenRouter、SiliconFlow 等），用户只需填入 API Key 即可快速创建 Provider
- **配置备份与回滚**：切换 Provider 前自动备份当前配置，支持回滚到之前的配置
- **导入已有配置**：首次使用时自动检测并导入 `~/.claude/settings.json` 中已有的 Provider 配置

## Capabilities

### New Capabilities
- `claude-provider-management`: Provider 的 CRUD、切换、预设管理，读写 `~/.claude/settings.json` 配置文件，配置备份与回滚
- `claude-mcp-management`: MCP 服务器的统一管理，添加/编辑/删除/启用禁用，同步到 `~/.claude.json` 的 mcpServers 区段
- `claude-skills-management`: Skills 的发现、安装、卸载、同步管理，从 GitHub 仓库浏览和一键安装，symlink 到 `~/.claude/skills/`

### Modified Capabilities
<!-- 无需修改现有规格 -->

## Impact

- **新增数据模型**：Provider、McpServer、Skill、SkillRepo 等 Swift 数据模型
- **新增服务层**：ClaudeProviderService、ClaudeMcpService、ClaudeSkillService 等 Swift 服务类
- **新增 UI 视图**：设置页新增 Claude Code 管理入口，包括 Provider 列表/表单、MCP 管理面板、Skills 管理面板
- **文件系统操作**：读写 `~/.claude/settings.json`、`~/.claude.json`、`~/.claude/skills/` 目录、`~/.launchx/claude/` 本地存储目录
- **数据存储**：使用 JSON 文件存储（`~/.launchx/claude/providers.json` 等），与 LaunchX 现有配置管理模式一致
- **网络请求**：GitHub API 调用（Skills 仓库浏览）、Provider 端点测速
- **回滚方案**：所有变更仅限于新增模块和设置页扩展，不修改现有功能的核心逻辑。如需回滚，移除新增的服务、模型和视图文件即可
