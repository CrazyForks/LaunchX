## 1. TOML 解析器基础设施

- [x] 1.1 实现 `CodexTomlParser` 类：支持解析 TOML flat key-value、`[table]` 嵌套表、`[[array]]` 数组表、inline table、基本类型（string, bool, integer, float, array）
- [x] 1.2 实现 `CodexTomlWriter` 类：将结构化数据序列化为 TOML 文本，保持非托管字段不丢失
- [ ] 1.3 为 TOML 解析器编写单元测试：覆盖 flat key、嵌套表、数组表、混合类型的解析和序列化

## 2. 数据模型层

- [x] 2.1 创建 `CodexProvider` 模型：包含 id, name, providerId, baseUrl, envKey, apiKey, wireApi, queryParams, model, category, isCurrent, sortIndex, notes, icon, iconColor, createdAt 字段
- [x] 2.2 创建 `CodexProviderCategory` 枚举：official, aggregator, third_party, cloud_provider, local
- [x] 2.3 创建 `CodexProviderPreset` 模型和 `CodexProviderPresetLoader`：定义 20+ 内置预设（OpenAI 官方、Azure、Bedrock、Ollama、LMStudio、主流第三方/中转站），实现 `createProvider(apiKey:)` 工厂方法
- [x] 2.4 创建 `CodexMcpServer` 模型：包含 id, name, serverType, command, args, url, env, isEnabled, startupTimeoutSec, toolTimeoutSec, enabledTools, disabledTools, bearerTokenEnvVar, httpHeaders, required, serverDescription, homepage, docs, tags 字段
- [x] 2.5 创建 `CodexMcpServerType` 枚举：stdio, streamable_http
- [x] 2.6 创建 `CodexSkill` 模型：包含 id, name, skillDescription, directory, repoOwner, repoName, repoBranch, readmeUrl, isEnabled, installedAt 字段
- [x] 2.7 创建 `CodexSkillRepo` 模型和 `CodexDiscoveredSkill` 模型

## 3. 数据存储层

- [x] 3.1 实现 `CodexDataStore` 单例：管理 `~/Library/Application Support/LaunchX/codex/` 目录，创建 providers.json, mcp_servers.json, skills.json, skill_repos.json 文件
- [x] 3.2 实现原子写入（write-to-temp + rename）和序列化 dispatch queue
- [x] 3.3 实现 config.toml 备份功能：备份到 `backups/config_YYYYMMDD_HHmmss.toml`，自动清理超过 10 份的旧备份
- [x] 3.4 实现备份列表和恢复功能

## 4. Provider 管理服务

- [x] 4.1 实现 `CodexProviderService` 单例（@MainActor + ObservableObject）：管理 providers 数组和 currentProvider
- [x] 4.2 实现 `readCodexConfig()` — 使用 TOML 解析器读取 `~/.codex/config.toml`
- [x] 4.3 实现 `writeCodexConfig()` — 使用 TOML 序列化器写入 `~/.codex/config.toml`（保留非托管字段）
- [x] 4.4 实现 Provider CRUD：addProvider, updateProvider, deleteProvider（拒绝删除当前激活）, getAllProviders
- [x] 4.5 实现 Provider 切换逻辑：backfill → 备份 → 更新 model_provider 字段 → 写入 [model_providers.<id>] 段 → 持久化 → 触发 MCP/Skills 同步
- [x] 4.6 实现 `importDefaultConfig()` — 首次使用时从 `~/.codex/config.toml` 导入现有 Provider 配置
- [x] 4.7 实现 `restoreFromBackup()` — 从备份文件恢复 config.toml

## 5. MCP Server 管理服务

- [x] 5.1 实现 `CodexMcpService` 单例（@MainActor + ObservableObject）：管理 servers 数组
- [x] 5.2 实现 MCP 配置校验：STDIO 需要 command，HTTP 需要 url
- [x] 5.3 实现 MCP Server CRUD：addServer（校验后）, updateServer, deleteServer, toggleEnabled
- [x] 5.4 实现 `syncToCodex()` — 将所有 MCP Server 写入 config.toml 的 [mcp_servers.*] 段
- [x] 5.5 实现 `importFromCodex()` — 从 config.toml 导入现有 MCP 配置，跳过重复

## 6. Skills 管理服务

- [x] 6.1 实现 `CodexSkillService` 单例（@MainActor + ObservableObject）：管理 skills, repos, discoveredSkills
- [x] 6.2 实现默认仓库初始化和自定义仓库管理（addRepo, removeRepo）
- [x] 6.3 实现 `discoverSkills()` — 并行扫描所有已启用仓库的 GitHub Git Trees API，解析 SKILL.md frontmatter
- [x] 6.4 实现 `installSkill()` — 下载 SKILL.md 到本地管理目录，创建 `~/.agents/skills/<name>/` 符号链接（失败时回退为复制）
- [x] 6.5 实现 `uninstallSkill()` — 移除符号链接/文件，删除本地目录，移除记录
- [x] 6.6 实现 `toggleEnabled()` — 创建/移除符号链接
- [x] 6.7 实现 `scanUnmanagedSkills()` — 扫描 `~/.agents/skills/` 中未管理的目录
- [x] 6.8 实现 `importSkill()` — 将未管理 Skill 纳入管理
- [x] 6.9 实现 `syncAllEnabled()` — 全量重建已启用 Skills 的符号链接

## 7. 设置界面 UI

- [x] 7.1 创建 `CodexSettingsView` — 主设置视图，包含启用/禁用开关、别名配置（默认 "cx"）、快捷键录制
- [x] 7.2 创建 `CodexProviderListView` — Provider 列表，显示当前激活标识，支持添加/编辑/删除/切换
- [x] 7.3 创建 `CodexProviderFormView` — Provider 编辑表单，包含所有字段（name, providerId, baseUrl, envKey, apiKey, wireApi, queryParams, model 等）
- [x] 7.4 创建 `CodexProviderPresetView` — 预设选择器，按分类分组展示，支持从预设创建 Provider
- [x] 7.5 创建 `CodexMcpServerListView` — MCP Server 列表，显示类型标识和启用状态
- [x] 7.6 创建 `CodexMcpServerFormView` — MCP Server 编辑表单，根据 serverType 动态显示字段
- [x] 7.7 创建 `CodexSkillListView` — 已安装 Skills 列表，显示来源仓库和启用状态
- [x] 7.8 创建 `CodexSkillRepoSettingsView` — Skill 仓库管理界面
- [x] 7.9 在主设置页面添加 Codex 设置入口

## 8. 搜索面板集成

- [x] 8.1 扩展 `SearchResult` 模型：新增 `isCodexEntry`, `isCodexItem`, `codexItemType`, `codexItemId` 字段和 `CodexItemType` 枚举
- [x] 8.2 在 `SearchPanelViewController+Search.swift` 中实现 `checkCodexAliasMatch()` 别名匹配
- [x] 8.3 在 `SearchPanelViewController+Modes.swift` 中实现 Codex Switcher 模式进入/退出逻辑
- [x] 8.4 实现 Codex Switcher 模式的分组列表加载（Provider / MCP / Skills）
- [x] 8.5 实现模式内搜索过滤
- [x] 8.6 实现选择操作响应：Enter 切换 Provider / 切换 MCP 启用 / 切换 Skill 启用
- [x] 8.7 实现列表项图标和状态的即时更新

## 9. 快捷键集成

- [x] 9.1 创建 `CodexSwitcherSettings` 模型（UserDefaults 持久化）：包含 isEnabled, alias, hotKey 字段
- [x] 9.2 在 `HotKeyService+CustomHotKeys.swift` 中实现 `registerCodexHotKey` / `unregisterCodexHotKey` / `loadCodexHotKey`

## 10. 集成测试

- [ ] 10.1 测试 TOML 解析器与真实 Codex config.toml 的兼容性
- [ ] 10.2 测试 Provider 切换流程：验证 config.toml 内容正确性
- [ ] 10.3 测试 MCP Server 同步：验证 config.toml 的 [mcp_servers.*] 段正确性
- [ ] 10.4 测试 Skill 安装和符号链接创建
- [ ] 10.5 测试首次导入：从现有 config.toml 导入 Provider 和 MCP 配置
- [ ] 10.6 测试搜索面板别名匹配和模式切换
