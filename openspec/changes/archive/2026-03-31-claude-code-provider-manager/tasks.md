## 1. 数据模型与基础架构

- [ ] 1.1 创建 ClaudeProvider 数据模型（Models/ClaudeProvider.swift），包含 id、name、settingsConfig、category、websiteUrl、notes、icon、iconColor、isCurrent、createdAt、sortIndex 等字段
- [ ] 1.2 创建 McpServer 数据模型（Models/McpServer.swift），包含 id、name、serverConfig、description、homepage、docs、tags、isEnabled 等字段
- [ ] 1.3 创建 Skill 数据模型（Models/ClaudeSkill.swift），包含 id、name、description、directory、repoOwner、repoName、repoBranch、readmeUrl、isEnabled、installedAt 等字段
- [ ] 1.4 创建 SkillRepo 数据模型（Models/SkillRepo.swift），包含 owner、name、branch、isEnabled 字段
- [ ] 1.5 创建 ProviderCategory 枚举（official、cn_official、aggregator、third_party、cloud_provider）
- [ ] 1.6 创建数据存储管理器（Services/Features/ClaudeCode/ClaudeDataStore.swift），负责读写 JSON 配置文件（providers.json、mcp_servers.json、skills.json、skill_repos.json），支持原子写入
- [ ] 1.7 创建目录初始化逻辑，确保 `~/Library/Application Support/LaunchX/claude/` 及子目录（backups/、skills/）存在

## 2. Provider 预设系统

- [ ] 2.1 创建 Provider 预设 JSON 文件（Resources/claude_provider_presets.json），包含 20+ 内置预设
- [ ] 2.2 创建 ClaudeProviderPreset 模型，支持模板值（templateValues）系统
- [ ] 2.3 创建预设加载器，从 Bundle 中读取预设 JSON 并解析为 [ClaudeProviderPreset] 数组

## 3. Provider 服务层

- [ ] 3.1 创建 ClaudeProviderService（Services/Features/ClaudeCode/ClaudeProviderService.swift），实现 Provider CRUD 操作
- [ ] 3.2 实现 addProvider 方法：创建 Provider 并持久化到 providers.json
- [ ] 3.3 实现 updateProvider 方法：更新 Provider 配置，若为当前激活则同步更新 settings.json
- [ ] 3.4 实现 deleteProvider 方法：删除非激活 Provider，激活 Provider 拒绝删除
- [ ] 3.5 实现 getAllProviders 方法：查询所有 Provider 列表
- [ ] 3.6 实现 switchProvider 方法：包含 backfill → 备份 → 写入 → 更新标志 → 触发 MCP/Skills 同步的完整流程
- [ ] 3.7 实现 importDefaultConfig 方法：首次使用时读取 ~/.claude/settings.json 并创建默认 Provider
- [ ] 3.8 实现 readClaudeSettings 方法：读取 ~/.claude/settings.json 内容
- [ ] 3.9 实现 writeClaudeSettings 方法：原子写入 ~/.claude/settings.json
- [ ] 3.10 实现备份与回滚逻辑：切换前备份到 backups/ 目录，保留最近 10 个备份
- [ ] 3.11 实现 backfill 逻辑：切换前将当前 settings.json 回填到旧 Provider

## 4. MCP 服务层

- [ ] 4.1 创建 ClaudeMcpService（Services/Features/ClaudeCode/ClaudeMcpService.swift），实现 MCP 服务器管理
- [ ] 4.2 实现 MCP 配置验证逻辑：stdio 类型校验 command、http/sse 类型校验 url
- [ ] 4.3 实现 CRUD 操作：添加、更新、删除 MCP 服务器
- [ ] 4.4 实现 toggleEnabled 方法：启用/禁用单个 MCP 服务器
- [ ] 4.5 实现 syncToClaude 方法：将所有 enabled 的 MCP 服务器全量同步到 ~/.claude.json 的 mcpServers 区段
- [ ] 4.6 实现 importFromClaude 方法：从 ~/.claude.json 的 mcpServers 导入已有配置
- [ ] 4.7 实现 readClaudeMcpConfig 方法：读取 ~/.claude.json 中的 mcpServers 区段

## 5. Skills 服务层

- [ ] 5.1 创建 ClaudeSkillService（Services/Features/ClaudeCode/ClaudeSkillService.swift），实现 Skills 管理
- [ ] 5.2 实现 Skill 仓库管理：初始化默认仓库、添加/移除自定义仓库
- [ ] 5.3 实现 discoverSkills 方法：通过 GitHub API 扫描仓库中的 SKILL.md 文件，解析 YAML frontmatter
- [ ] 5.4 实现 installSkill 方法：从 GitHub 下载 SKILL.md → 保存到本地 → 创建 symlink 到 ~/.claude/skills/
- [ ] 5.5 实现 symlink 降级逻辑：symlink 失败时 fallback 到文件复制
- [ ] 5.6 实现 uninstallSkill 方法：删除 symlink/文件副本 + 删除本地主副本 + 移除记录
- [ ] 5.7 实现 toggleSkillEnabled 方法：启用时创建 symlink/复制，禁用时移除
- [ ] 5.8 实现 scanUnmanagedSkills 方法：扫描 ~/.claude/skills/ 中未管理的 Skills
- [ ] 5.9 实现 importSkills 方法：从目录导入已有 Skills
- [ ] 5.10 实现 syncAllEnabled 方法：Provider 切换时同步所有已启用 Skills

## 6. UI 视图 — Provider 管理

- [ ] 6.1 创建 ClaudeCodeSettingsView（Views/Settings/Extensions/ClaudeCodeSettingsView.swift），作为 Claude Code 管理的主视图
- [ ] 6.2 创建 ProviderListView：展示 Provider 列表，当前激活 Provider 高亮，支持拖拽排序
- [ ] 6.3 创建 ProviderFormView：Provider 添加/编辑表单（名称、API Key 密码框、Base URL、模型、分类、备注）
- [ ] 6.4 创建 ProviderPresetView：预设选择器，按 category 分组展示预设列表
- [ ] 6.5 创建 ProviderDetailView：展示单个 Provider 的详细信息和操作按钮（编辑、删除、启用）

## 7. UI 视图 — MCP 管理

- [ ] 7.1 创建 McpServerListView：展示 MCP 服务器列表，每个显示名称、启用开关、配置类型
- [ ] 7.2 创建 McpServerFormView：MCP 服务器添加/编辑表单（名称、JSON 配置编辑器）
- [ ] 7.3 将 MCP 管理面板集成到 ClaudeCodeSettingsView 中（Tab 或 Sheet 方式）

## 8. UI 视图 — Skills 管理

- [ ] 8.1 创建 SkillListView：展示已安装 Skills 列表，显示名称、来源、启用开关
- [ ] 8.2 创建 SkillDiscoverView：从仓库浏览可用 Skills，支持安装/卸载操作
- [ ] 8.3 创建 SkillRepoSettingsView：管理 Skills 来源仓库（添加/移除 GitHub 仓库）
- [ ] 8.4 将 Skills 管理面板集成到 ClaudeCodeSettingsView 中

## 9. 集成与设置页入口

- [ ] 9.1 在 SettingsView 的高级扩展区域添加"Claude Code"入口，点击打开 ClaudeCodeSettingsView
- [ ] 9.2 将 ClaudeProviderService、ClaudeMcpService、ClaudeSkillService 注册到应用生命周期管理中
- [ ] 9.3 实现首次打开时的自动导入逻辑：检测已有 Claude Code 配置并导入为默认 Provider 和 MCP 服务器
- [ ] 9.4 确保各 Service 的初始化和目录创建在 App 启动时完成
