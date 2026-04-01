## Why

当前高级扩展的导出/导入功能中，Claude Code 部分仅导出了 `ClaudeCodeSwitcherSettings` 和 `ClaudeProvider` 列表，缺少 MCP 服务器配置。用户在迁移或备份配置时，MCP 服务器数据会丢失，需要手动重新配置所有 MCP 服务器。

## What Changes

- 在 `BackupModel` 中新增 `mcpServers: [McpServer]` 字段，导出时包含完整的 MCP 服务器配置
- 在 `BackupModel.createCurrent()` 中读取当前 MCP 服务器数据
- 在 `BackupModel.apply()` 中还原 MCP 服务器数据并触发同步到 `~/.claude.json`
- 备份版本号保持 "2.0"，通过可选解码实现向后兼容（旧备份无 mcpServers 字段时使用空数组）

## Capabilities

### New Capabilities

（无新增能力）

### Modified Capabilities

- `advanced-extensions-backup`: 导出/导入范围扩展，新增 MCP 服务器数据的导出和导入支持
- `claude-mcp-management`: 导入后需触发 MCP 同步到 `~/.claude.json`

## Impact

- **BackupModel.swift** — 新增 `mcpServers` 字段、修改 init/decoder/createCurrent/apply
- **BackupService.swift** — 无需修改（逻辑已由 BackupModel 封装）
- **ClaudeMcpService.swift** — 导入后可能需要调用同步方法
- **向后兼容** — 旧版 v2.0 备份文件不含 mcpServers 字段，导入时应优雅处理为空数组
- **回滚方案** — 若出现问题，移除 mcpServers 相关字段即可恢复原状；旧备份文件不受影响
