## Context

LaunchX 已有完整的 Claude Code 配置管理模块（Provider/MCP/Skills），采用三层架构：Model（纯 Codable 结构体）→ DataStore（文件 I/O）→ Service（业务逻辑 + UI 状态）。现需要为 OpenAI Codex CLI 实现对等的配置管理功能。

关键差异点：
- **配置格式**: Claude Code 使用 JSON，Codex 使用 TOML
- **配置路径**: Claude Code 使用 `~/.claude/`，Codex 使用 `~/.codex/`
- **Provider 模型**: Claude Code 通过 `env` 变量切换，Codex 通过 `[model_providers.<id>]` TOML 表 + `model_provider` 字段切换
- **MCP 配置**: Claude Code 在 `~/.claude.json` 的 `mcpServers` 键，Codex 在 `config.toml` 的 `[mcp_servers.<name>]` 段
- **Skills 路径**: Claude Code 用 `~/.claude/skills/`，Codex 用 `~/.agents/skills/`（开放标准）

## Goals / Non-Goals

**Goals:**
- 为 Codex CLI 提供与 Claude Code 对等的 Provider/MCP/Skills 管理
- 复用现有架构模式（三层架构、Singleton + MainActor、原子写入）
- 搜索面板集成 Codex Switcher 模式（别名 `cx`）
- 支持 20+ Codex Provider 预设
- 配置操作前自动备份

**Non-Goals:**
- 不支持 Codex 的 Profiles、Subagents、Hooks 等高级配置（后续可扩展）
- 不支持 Codex 的权限管理（permissions、trust_level）
- 不替代 Codex CLI 本身的任何功能
- 不做两个工具间的配置迁移

## Decisions

### Decision 1: TOML 解析方案 — 自实现轻量 TOML Parser

**选择**: 自己实现一个轻量的 TOML 解析/生成器，内嵌在项目中。

**理由**:
- 项目不使用 Swift Package Manager（纯 Xcode 项目），引入第三方 TOML 库需要手动集成源码
- Codex 的 `config.toml` 结构相对简单（flat key + `[table]` + `[[array]]`），不需要完整的 TOML 1.0 支持
- Claude Code 模块已经直接操作 JSON 字符串，TOML 操作保持一致风格

**替代方案**:
- 集成 `TOMLKit` Swift 库 — 功能完整但引入外部依赖
- 调用 `python3 -c "import toml; ..."` 做 TOML↔JSON 转换 — 需要系统 Python，不可靠

**实现策略**: `CodexTomlParser` 类，支持读/写 flat key-value、`[table]` 嵌套表、`[[array]]` 数组表。输出时保持注释和格式（至少保持非托管字段不丢失）。

### Decision 2: Data 隔离 — 独立 CodexDataStore

**选择**: 创建独立的 `CodexDataStore`（类似 `ClaudeDataStore`），数据存储在 `~/Library/Application Support/LaunchX/codex/`。

**理由**:
- 与 Claude Code 模块完全解耦，互不影响
- 备份策略独立（Codex 备份 `config.toml`，Claude 备份 `settings.json`）
- 可以独立禁用某个模块而不影响另一个

### Decision 3: Provider 模型 — 映射到 TOML `[model_providers.<id>]`

**选择**: `CodexProvider` 模型包含 Codex 特有字段（`providerId`, `baseUrl`, `envKey`, `wireApi`, `queryParams` 等），切换时写入 `config.toml` 的 `model_provider` + `[model_providers.<id>]` 段。

**理由**: Codex 的 Provider 系统比 Claude Code 更结构化，有独立的 provider 概念和嵌套配置。直接映射到 Codex 的 TOML 结构最自然。

```
切换 Provider 流程:
1. 读取当前 ~/.codex/config.toml
2. Backfill 当前 provider 配置回数据模型
3. 备份 config.toml
4. 更新 config.toml: model_provider = "<providerId>"
5. 写入/更新 [model_providers.<providerId>] 段
6. 持久化 providers 数据
7. 触发 MCP + Skills 同步
```

### Decision 4: MCP Server 管理 — TOML `[mcp_servers.<name>]` 段

**选择**: `CodexMcpServer` 模型支持 STDIO 和 Streamable HTTP 两种类型，映射到 `config.toml` 的 `[mcp_servers.<name>]` 段。

**理由**: Codex 的 MCP 配置字段比 Claude Code 更丰富（`startup_timeout_sec`, `tool_timeout_sec`, `enabled_tools`, `disabled_tools`, `bearer_token_env_var` 等），需要扩展模型字段。

### Decision 5: Skills 管理 — 使用 `~/.agents/skills/` 标准

**选择**: Skills 安装到 `~/.agents/skills/<name>/` 目录（Codex 的标准路径），LaunchX 本地存储在 `~/Library/Application Support/LaunchX/codex/skills/`。

**理由**: Codex 使用开放的 agent skills 标准，skills 放在 `~/.agents/skills/`。遵循标准路径确保 Codex CLI 能正确发现已安装的 skills。

### Decision 6: 搜索面板集成 — 别名 `cx`

**选择**: 使用 `cx` 作为 Codex Switcher 的默认别名（类比 `cc` 用于 Claude Code）。

**理由**: `cx` 是 "Codex" 的自然缩写，简短且不与现有别名冲突。

### Decision 7: UI 复用策略 — 共享组件 + Codex 特化

**选择**: Provider/MCP/Skills 的列表和表单 UI 新建 Codex 专用视图，但提取可复用的布局组件（如 `ToggleRow`, `SectionHeaderView` 等）。

**理由**: 虽然 UI 布局相似，但 Codex 和 Claude Code 的字段差异较大（Codex Provider 有 `wireApi`、`queryParams` 等 Claude 没有的字段），强行抽象会增加复杂度。

## Risks / Trade-offs

**[风险] TOML 解析不完整** → 自实现的解析器可能不支持某些边缘语法（多行字符串、日期时间等）。缓解：只解析 Codex 用到的字段类型（string, bool, integer, array, inline table），遇到不识别的字段保留原始文本。

**[风险] config.toml 格式变更** → Codex CLI 仍在快速迭代，配置格式可能变化。缓解：TOML 解析器设计为 tolerant，未识别的字段原样保留；模块设计为可快速更新。

**[风险] 与用户手动编辑冲突** → 用户可能同时通过 LaunchX 和手动编辑 `config.toml`。缓解：每次操作前读取最新文件（backfill 模式），原子写入避免损坏。

**[权衡] 不依赖外部 TOML 库** → 自实现解析器代码量较少但功能受限。如果未来 Codex 配置变复杂，可能需要切换到第三方库。

## Migration Plan

1. 此为纯新增功能，不影响现有 Claude Code 模块
2. 首次启动时检测 `~/.codex/config.toml` 是否存在，自动导入现有配置
3. 回滚策略：删除 `~/Library/Application Support/LaunchX/codex/` 目录即可，原始 `~/.codex/config.toml` 不受影响（有备份）
4. 功能通过开关控制，可独立禁用
