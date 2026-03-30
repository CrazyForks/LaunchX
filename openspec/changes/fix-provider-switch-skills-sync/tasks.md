## 1. Provider 切换修复

- [x] 1.1 修复 `ClaudeProviderService.writeClaudeSettings`：在 `moveItem` 前先 `removeItem` 旧文件（参照 `ClaudeMcpService.syncToClaude` 的正确实现），catch 块改为 `throw` 而非静默吞掉
- [x] 1.2 修复 `ClaudeProviderService.backfillCurrentProvider`：在 backfill 前保存旧 provider 的 `settingsConfig` 快照，传入 `switchProvider` 中以便失败时回滚
- [x] 1.3 修复 `ClaudeProviderService.switchProvider`：backfill 保存快照 → writeClaudeSettings → 成功则 persistData，失败则用快照恢复旧 provider 数据并 throw
- [ ] 1.4 验证：添加两个不同 URL 的 provider，切换后确认 settings.json 被正确更新、旧 provider 数据不变

## 2. MCP 管理修复

- [x] 2.1 修复 `ClaudeMcpService.persistData`：从 `try? store.saveMcpServers(servers)` 改为 `try store.saveMcpServers(servers)` 并让调用方处理错误
- [x] 2.2 修复所有 MCP CRUD 方法（addServer、updateServer、deleteServer、toggleEnabled）：persistData 失败时向调用方反馈错误
- [x] 2.3 修复 `syncToClaude`：catch 块改为 `throw`，确保调用方能感知同步失败
- [ ] 2.4 验证：添加一个 MCP server，检查 `mcp_servers.json` 和 `~/.claude.json` 的 `mcpServers` 字段是否都被正确更新

## 3. Skills 同步修复

- [x] 3.1 修复 `ClaudeSkillService.createSkillLink`：在 `claudeSkillsDir.appendingPathComponent(directory)` 前对 `directory` 进行 sanitize，去掉开头的 `skills/` 前缀
- [x] 3.2 修复 `installSkill`：同样对 `directory` 进行 sanitize，确保本地主副本保存到正确路径
- [x] 3.3 修复 `persistSkills`：从 `try?` 改为 `throws`，让调用方感知持久化失败
- [x] 3.4 清理错误的嵌套目录：删除 `~/.claude/skills/skills/` 如果存在
- [ ] 3.5 验证：安装一个 skill，检查 `~/.claude/skills/{name}/SKILL.md` 路径正确、`skills.json` 有记录

## 4. 错误反馈统一

- [x] 4.1 `ClaudeDataStore` 的 `saveProviders`、`saveMcpServers`、`saveSkills` 保持 throws（当前已经是 throws，只是调用方用 try? 吞掉了）
- [x] 4.2 `ProviderListView.activateProvider`：确保 catch 块覆盖所有 switchProvider 可能抛出的错误（当前已有，验证即可）
- [x] 4.3 `McpServerListView`：为 MCP CRUD 操作的失败情况添加 alert 显示（参照 ProviderListView 的 errorMessage 模式）
- [x] 4.4 `McpServerFormView.saveServer`：捕获 persistData 和 syncToClaude 的错误并显示给用户

## 5. 集成验证

- [ ] 5.1 端到端测试：添加两个 Provider → 切换 → 验证 settings.json 正确 → 切回 → 验证旧 Provider 数据完整
- [ ] 5.2 端到端测试：添加 MCP server → 验证 ~/.claude.json 包含 mcpServers → 删除 → 验证 mcpServers 被清空
- [ ] 5.3 端到端测试：安装 Skill → 验证路径正确 → 切换 Provider → 验证 Skill 仍可被 Claude Code 识别
