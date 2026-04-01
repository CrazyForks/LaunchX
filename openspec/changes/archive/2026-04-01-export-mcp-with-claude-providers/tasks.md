## 1. BackupModel 数据模型修改

- [x] 1.1 在 BackupModel 中添加 `mcpServers: [McpServer]` 属性字段（位于 `claudeProviders` 之后）
- [x] 1.2 修改自定义 `init(from decoder:)` 解码器，使用 `decodeIfPresent` 解码 mcpServers，缺失时默认为空数组（保持 MCP 列表不变，不覆盖）
- [x] 1.3 修改直接初始化器 `init(metadata:...mcpServers:)` 添加 mcpServers 参数
- [x] 1.4 修改 `createCurrent()` 方法，从 `ClaudeDataStore.shared.loadMcpServers()` 读取 MCP 数据并传入

## 2. 导入还原逻辑

- [x] 2.1 修改 `apply()` 方法，当 mcpServers 非空时调用 `ClaudeDataStore.shared.saveMcpServers(mcpServers)` 保存数据
- [x] 2.2 在 `apply()` 中保存 MCP 数据后，调用 `ClaudeMcpService.shared.syncToClaude()` 将启用的 MCP 服务器同步到 `~/.claude.json`

## 3. 验证

- [x] 3.1 编译项目确认无编译错误
- [ ] 3.2 测试导出：导出配置文件，验证 JSON 中包含 `mcpServers` 字段且数据正确
- [ ] 3.3 测试导入（新备份）：导入包含 mcpServers 的备份，验证 MCP 服务器正确还原并同步到 `~/.claude.json`
- [ ] 3.4 测试向后兼容：导入不含 mcpServers 字段的旧 v2.0 备份文件，验证不报错且 MCP 列表不受影响
