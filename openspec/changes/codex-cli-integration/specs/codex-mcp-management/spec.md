## ADDED Requirements

### Requirement: Codex MCP Server 数据模型
系统 SHALL 提供 `CodexMcpServer` 模型，包含以下字段：`id`（UUID）、`name`（服务器名称）、`serverType`（`stdio` 或 `streamable_http`）、`command`（STDIO 启动命令）、`args`（命令参数数组）、`url`（HTTP 端点 URL）、`env`（环境变量字典）、`isEnabled`（启用状态）、`startupTimeoutSec`（启动超时，默认 10）、`toolTimeoutSec`（工具超时，默认 60）、`enabledTools`（白名单）、`disabledTools`（黑名单）、`bearerTokenEnvVar`（HTTP 认证 token 环境变量）、`httpHeaders`（静态 HTTP 头）、`required`（启动失败是否报错）、`serverDescription`、`homepage`、`docs`、`tags`。模型 SHALL 遵循 `Codable` + `Identifiable` + `Equatable`。

#### Scenario: 创建 STDIO 类型 MCP Server
- **WHEN** 用户添加一个 STDIO 类型的 MCP Server，指定 command="npx"、args=["-y", "@upstash/context7-mcp"]
- **THEN** 系统创建 `CodexMcpServer` 实例，`serverType` 为 `stdio`

#### Scenario: 创建 Streamable HTTP 类型 MCP Server
- **WHEN** 用户添加一个 HTTP 类型的 MCP Server，指定 url="https://example.com/mcp"
- **THEN** 系统创建 `CodexMcpServer` 实例，`serverType` 为 `streamable_http`

### Requirement: MCP Server 配置校验
系统 SHALL 在保存 MCP Server 前校验配置完整性：STDIO 类型必须提供 `command`，Streamable HTTP 类型必须提供 `url`。校验失败时返回具体的错误信息。

#### Scenario: STDIO 缺少 command
- **WHEN** 用户保存 STDIO 类型的 Server 但未填写 command
- **THEN** 系统返回 "STDIO 类型必须指定启动命令" 错误

#### Scenario: HTTP 缺少 url
- **WHEN** 用户保存 HTTP 类型的 Server 但未填写 url
- **THEN** 系统返回 "HTTP 类型必须指定服务器 URL" 错误

### Requirement: MCP Server 同步到 config.toml
系统 SHALL 将所有已启用的 MCP Server 写入 `~/.codex/config.toml` 的 `[mcp_servers.<name>]` 段。STDIO 类型写入 `command`、`args`、`env`、`startup_timeout_sec`、`tool_timeout_sec` 等字段；HTTP 类型写入 `url`、`bearer_token_env_var`、`http_headers` 等字段。已禁用的 Server 写入 `enabled = false`。

#### Scenario: 同步 STDIO Server
- **WHEN** 系统同步一个 STDIO 类型的 Server（name="context7"，command="npx"，args=["-y", "@upstash/context7-mcp"]）
- **THEN** config.toml 中新增 `[mcp_servers.context7]` 段，包含 `command = "npx"`、`args = ["-y", "@upstash/context7-mcp"]`

#### Scenario: 同步已禁用的 Server
- **WHEN** 一个 MCP Server 被禁用
- **THEN** config.toml 中对应的段保留但添加 `enabled = false`

#### Scenario: 同步 HTTP Server
- **WHEN** 系统同步一个 HTTP 类型的 Server（name="remote"，url="https://api.example.com/mcp"）
- **THEN** config.toml 中新增 `[mcp_servers.remote]` 段，包含 `url = "https://api.example.com/mcp"`

### Requirement: MCP Server CRUD 操作
系统 SHALL 支持 MCP Server 的增删改查：添加新 Server（校验后）、编辑配置、删除 Server、切换启用/禁用状态。

#### Scenario: 切换 Server 启用状态
- **WHEN** 用户切换一个已启用的 Server 为禁用
- **THEN** 系统更新 `isEnabled` 为 false，持久化数据，同步到 config.toml

#### Scenario: 删除 Server
- **WHEN** 用户删除一个 MCP Server
- **THEN** 系统从数据中移除该记录，持久化，同步到 config.toml

### Requirement: 从现有 config.toml 导入 MCP
系统 SHALL 支持从 `~/.codex/config.toml` 的 `[mcp_servers.*]` 段导入现有的 MCP Server 配置，自动识别 STDIO/HTTP 类型并创建对应的 `CodexMcpServer` 实例。重复的 Server（同名）不重复导入。

#### Scenario: 导入已有的 MCP 配置
- **WHEN** 用户的 config.toml 中已有 `[mcp_servers.context7]` 段
- **THEN** 系统解析该段并创建对应的 `CodexMcpServer` 实例

#### Scenario: 导入时跳过重复
- **WHEN** 导入的 Server 名称与已有记录重复
- **THEN** 系统跳过该 Server，不重复导入

### Requirement: MCP 配置原子写入
系统 SHALL 使用原子写入策略更新 config.toml：先写入临时文件，再通过 rename 替换原文件，防止写入中断导致配置损坏。

#### Scenario: 写入过程中断
- **WHEN** 系统正在写入 config.toml 时进程中断
- **THEN** 原始 config.toml 保持不变（因为 rename 是原子操作）
