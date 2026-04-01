## Context

当前 `BackupModel` (v2.0) 在 Claude Code 模块中仅导出 `ClaudeCodeSwitcherSettings` 和 `[ClaudeProvider]`，而 MCP 服务器数据（`[McpServer]`）存储在独立的 `mcp_servers.json` 文件中，未被纳入备份范围。用户在迁移配置时会丢失所有 MCP 服务器配置。

数据流现状：
- `ClaudeDataStore` 负责 providers 和 mcpServers 的读写
- `ClaudeMcpService` 负责 MCP 服务器与 `~/.claude.json` 的双向同步
- `BackupModel.createCurrent()` 和 `apply()` 是导出/导入的核心入口

## Goals / Non-Goals

**Goals:**
- 将 MCP 服务器数据纳入备份导出/导入流程
- 导入后自动同步 MCP 配置到 `~/.claude.json`
- 向后兼容：不含 mcpServers 字段的旧 v2.0 备份文件可正常导入

**Non-Goals:**
- 不改变备份文件版本号（保持 "2.0"）
- 不修改 BackupService 的 UI 流程
- 不涉及 Skills 和 SkillRepos 的导出（不在本次范围内）

## Decisions

### 1. 使用可选解码实现向后兼容

**决定**：在自定义 `init(from decoder:)` 中使用 `decodeIfPresent` 解码 `mcpServers`，缺失时默认为空数组。

**理由**：保持版本号为 "2.0"，避免引入版本迁移逻辑。旧备份文件只是缺少这个字段，不应因此无法导入。

**替代方案**：升级版本号到 "3.0" 并强制包含新字段 → 过于重量级，且会导致旧版本无法兼容。

### 2. 导入后触发 MCP 同步

**决定**：在 `apply()` 中保存 mcpServers 后，调用 `ClaudeMcpService` 将启用的 MCP 服务器同步到 `~/.claude.json`。

**理由**：MCP 配置生效需要写入 `~/.claude.json`，仅保存到 `mcp_servers.json` 不够。

### 3. 不修改直接初始化器的参数签名

**决定**：在直接初始化器中也添加 `mcpServers` 参数，保持与 Codable 路径一致。

**理由**：`createCurrent()` 使用直接初始化器构造 BackupModel，必须传入完整数据。

## Risks / Trade-offs

- **[Risk] AnyCodable 编码兼容性** → `McpServer.serverConfig` 使用 `AnyCodable` 包装任意 JSON 值，需确保其在 JSONEncoder/JSONDecoder 往返编解码中不会丢失类型信息。当前实现已支持此场景。
- **[Risk] 大量 MCP 配置增加备份文件体积** → MCP 服务器配置通常为小型 JSON 对象，即使数十个服务器也不会显著影响文件大小。
- **[Trade-off] 不升级版本号** → 旧版本 app 导入新备份时，会因遇到未知字段 `mcpServers` 而解码失败。但这是可接受的，因为用户通常在同一版本间迁移。

## Migration Plan

1. 修改 `BackupModel` 添加 `mcpServers` 字段
2. 更新 `createCurrent()` 和 `apply()` 方法
3. 测试：旧备份导入（无 mcpServers）→ MCP 列表为空，不报错
4. 测试：新备份导入 → MCP 数据正确还原并同步
5. **回滚**：移除 mcpServers 相关代码，旧备份文件不受影响
