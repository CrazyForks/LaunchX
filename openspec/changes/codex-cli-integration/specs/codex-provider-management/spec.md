## ADDED Requirements

### Requirement: Codex Provider 数据模型
系统 SHALL 提供 `CodexProvider` 模型，包含以下字段：`id`（UUID）、`name`（显示名称）、`providerId`（Codex 配置中的 provider 标识符）、`baseUrl`（API 端点 URL）、`envKey`（API Key 环境变量名）、`apiKey`（用户填写的 API Key 值）、`wireApi`（通信协议，`responses` 或 `chat_completions`）、`queryParams`（URL 查询参数字典）、`model`（默认模型名）、`category`（分类：official/aggregator/third_party/cloud_provider/local）、`isCurrent`（是否当前激活）、`sortIndex`、`notes`、`icon`、`iconColor`、`createdAt`。模型 SHALL 遵循 `Codable` + `Identifiable` + `Equatable` 协议。

#### Scenario: 创建 Provider 实例
- **WHEN** 用户通过预设创建一个 OpenAI 官方 Provider
- **THEN** 系统创建 `CodexProvider` 实例，`providerId` 为 `"openai"`，`baseUrl` 为 `"https://api.openai.com/v1"`，`envKey` 为 `"OPENAI_API_KEY"`，`wireApi` 为 `"responses"`

#### Scenario: 创建自定义 Provider
- **WHEN** 用户手动创建一个自定义 Provider，指定 baseUrl 和 envKey
- **THEN** 系统创建实例，`providerId` 由用户指定的标识符决定，`category` 为 `third_party`

### Requirement: Codex Provider 预设
系统 SHALL 提供内置的 `CodexProviderPreset` 列表，至少包含 20 个预设：OpenAI 官方、Azure OpenAI、Amazon Bedrock、Ollama、LMStudio、以及主流第三方/中转站 Provider。每个预设 SHALL 包含 `id`、`name`、`providerId`、`baseUrl`、`envKey`、`wireApi`、`category`、`model`、`icon`、`notes`、`websiteUrl` 等字段，并提供 `createProvider(apiKey:)` 工厂方法。

#### Scenario: 使用预设创建 Provider
- **WHEN** 用户选择 "OpenAI 官方" 预设并输入 API Key
- **THEN** 系统通过 `createProvider(apiKey:)` 生成完整的 `CodexProvider` 实例，自动填充 baseUrl 和默认模型

#### Scenario: 预设按分类分组展示
- **WHEN** 用户浏览预设列表
- **THEN** 预设按 category 分组展示（官方/聚合器/第三方/云提供商/本地）

### Requirement: Provider 切换到 config.toml
系统 SHALL 在切换 Provider 时，将目标 Provider 的配置写入 `~/.codex/config.toml`：更新 `model_provider` 字段为目标 providerId，创建或更新 `[model_providers.<providerId>]` TOML 表（包含 `name`、`base_url`、`env_key`、`wire_api`、`query_params` 等字段），以及 `model` 字段。

#### Scenario: 切换到自定义 Provider
- **WHEN** 用户激活一个自定义 Provider（providerId="mistral"，baseUrl="https://api.mistral.ai/v1"，envKey="MISTRAL_API_KEY"）
- **THEN** 系统更新 `config.toml`：`model_provider = "mistral"`，新增 `[model_providers.mistral]` 表，`model` 更新为该 Provider 的默认模型

#### Scenario: 切换回 OpenAI 官方 Provider
- **WHEN** 用户切换回 OpenAI 官方 Provider（内置 providerId="openai"）
- **THEN** 系统更新 `config.toml`：`model_provider = "openai"`，移除之前自定义 Provider 的 `[model_providers.mistral]` 段（如果不再需要），保留其他用户手动添加的 provider 段

### Requirement: Provider 切换前 backfill
系统 SHALL 在切换 Provider 前，读取当前 `~/.codex/config.toml` 中的实际配置，回写到当前活跃 Provider 的数据模型中。这确保了用户手动编辑配置不会丢失。

#### Scenario: 手动编辑后 backfill
- **WHEN** 用户在 config.toml 中手动修改了当前 Provider 的 base_url，然后通过 LaunchX 切换到另一个 Provider
- **THEN** 系统在切换前读取最新 config.toml，将修改后的 base_url 回写到当前 Provider 记录中

### Requirement: config.toml 备份
系统 SHALL 在每次修改 `~/.codex/config.toml` 前创建备份，备份存储在 `~/Library/Application Support/LaunchX/codex/backups/` 目录，文件名格式为 `config_YYYYMMDD_HHmmss.toml`，最多保留 10 份备份。

#### Scenario: 首次切换 Provider 时创建备份
- **WHEN** 用户首次切换 Provider
- **THEN** 系统在写入前将当前 config.toml 复制到 backups 目录

#### Scenario: 备份数量超限
- **WHEN** 备份文件数量超过 10 个
- **THEN** 系统删除最旧的备份文件

### Requirement: 从现有 config.toml 导入
系统 SHALL 支持首次使用时从 `~/.codex/config.toml` 导入现有配置，自动识别已配置的 `model_provider` 和 `[model_providers.*]` 段，生成对应的 `CodexProvider` 实例。

#### Scenario: 导入包含自定义 Provider 的配置
- **WHEN** 用户的 config.toml 中已有 `[model_providers.myprovider]` 段
- **THEN** 系统创建对应的 `CodexProvider` 实例，标记为 `isCurrent`

### Requirement: Provider CRUD 操作
系统 SHALL 支持 Provider 的增删改查操作：添加新 Provider、编辑现有 Provider 配置、删除 Provider（当前激活的 Provider 不允许删除）、列出所有 Provider。

#### Scenario: 删除当前激活的 Provider
- **WHEN** 用户尝试删除当前正在使用的 Provider
- **THEN** 系统拒绝操作并返回错误提示

#### Scenario: 添加新 Provider
- **WHEN** 用户填写 Provider 表单并保存
- **THEN** 系统创建新 Provider 实例，持久化到 `providers.json`，如果是第一个 Provider 则自动激活

### Requirement: Provider 切换后触发级联同步
系统 SHALL 在 Provider 切换完成后，触发 MCP Server 同步和 Skills 同步，确保相关配置与当前 Provider 一致。

#### Scenario: Provider 切换后同步 MCP
- **WHEN** Provider 切换成功
- **THEN** 系统调用 `CodexMcpService.syncToCodex()` 同步 MCP 配置到 config.toml
