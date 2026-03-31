## ADDED Requirements

### Requirement: MCP 服务器数据模型
系统 SHALL 定义 McpServer 数据模型，包含以下字段：
- id: 唯一标识符（UUID）
- name: 服务器名称
- serverConfig: JSON 字典，包含 MCP 服务器配置（command、args、url 等）
- description: 描述（可选）
- homepage: 主页链接（可选）
- docs: 文档链接（可选）
- tags: 标签数组
- isEnabled: 是否启用（控制是否同步到 Claude Code）

#### Scenario: MCP 服务器数据持久化
- **WHEN** MCP 服务器数据发生变化
- **THEN** 系统 SHALL 将变更持久化到 `~/Library/Application Support/LaunchX/claude/mcp_servers.json`

### Requirement: MCP 配置验证
系统 SHALL 验证 MCP 服务器配置的有效性。

#### Scenario: stdio 类型服务器验证
- **WHEN** 用户添加一个 stdio 类型的 MCP 服务器配置
- **THEN** 系统 SHALL 验证配置中包含非空的 command 字段

#### Scenario: HTTP/SSE 类型服务器验证
- **WHEN** 用户添加一个 http 或 sse 类型的 MCP 服务器配置
- **THEN** 系统 SHALL 验证配置中包含非空的 url 字段

#### Scenario: 无效配置拒绝
- **WHEN** 用户提交的 MCP 服务器配置未通过验证
- **THEN** 系统 SHALL 拒绝保存并显示具体的验证错误信息

### Requirement: MCP CRUD 操作
系统 SHALL 支持对 MCP 服务器的完整增删改查操作。

#### Scenario: 添加 MCP 服务器
- **WHEN** 用户填写 MCP 服务器名称和配置（command/args 或 url）并保存
- **THEN** 系统创建新的 McpServer 记录，保存到 mcp_servers.json，并同步到 `~/.claude.json`

#### Scenario: 编辑 MCP 服务器
- **WHEN** 用户修改已有 MCP 服务器的配置
- **THEN** 系统更新记录，如果该服务器处于启用状态，SHALL 同步更新 `~/.claude.json`

#### Scenario: 删除 MCP 服务器
- **WHEN** 用户删除一个 MCP 服务器
- **THEN** 系统从 mcp_servers.json 中移除记录，并从 `~/.claude.json` 的 mcpServers 区段中移除对应条目

#### Scenario: 查询 MCP 服务器列表
- **WHEN** 用户打开 MCP 管理界面
- **THEN** 系统展示所有 MCP 服务器，每个服务器显示名称、配置摘要、启用状态

### Requirement: MCP 启用/禁用切换
系统 SHALL 支持单个 MCP 服务器的启用/禁用切换。

#### Scenario: 启用 MCP 服务器
- **WHEN** 用户将一个 MCP 服务器设置为启用
- **THEN** 系统 SHALL 将该服务器的配置写入 `~/.claude.json` 的 mcpServers 区段

#### Scenario: 禁用 MCP 服务器
- **WHEN** 用户将一个 MCP 服务器设置为禁用
- **THEN** 系统 SHALL 从 `~/.claude.json` 的 mcpServers 区段中移除该服务器条目

### Requirement: MCP 同步到 Claude Code
系统 SHALL 将所有启用的 MCP 服务器同步到 Claude Code 的配置文件。

#### Scenario: 全量同步
- **WHEN** Provider 切换触发 MCP 同步，或用户手动触发同步
- **THEN** 系统 SHALL 读取 `~/.claude.json`，保留非 mcpServers 区段的内容不变，用所有 enabled 的 MCP 服务器配置替换 mcpServers 区段

#### Scenario: 从 Claude Code 导入 MCP
- **WHEN** 首次打开 MCP 管理功能，且 `~/.claude.json` 已包含 mcpServers 配置
- **THEN** 系统 SHALL 读取现有 mcpServers，逐个验证后导入到 mcp_servers.json，标记为已启用

### Requirement: MCP 管理界面
系统 SHALL 提供 MCP 服务器管理界面。

#### Scenario: MCP 服务器列表
- **WHEN** 用户打开 MCP 管理面板
- **THEN** 系统展示所有 MCP 服务器列表，每个显示名称、启用开关、配置类型（stdio/http/sse）

#### Scenario: MCP 编辑表单
- **WHEN** 用户添加或编辑 MCP 服务器
- **THEN** 系统展示表单，支持 JSON 编辑器直接编辑 serverConfig，或通过模板表单配置常见参数（command、args、env 等）
