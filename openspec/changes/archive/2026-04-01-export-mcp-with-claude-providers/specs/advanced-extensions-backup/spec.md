## MODIFIED Requirements

### Requirement: 导出包含全部高级扩展模块配置
导出的备份文件 SHALL 包含以下模块的完整配置：
- ClipboardSettings（剪贴板）
- SnippetSettings + Snippet 数据
- AITranslateSettings（AI 翻译）
- BookmarkSettings（书签搜索）
- TwoFactorAuthSettings（2FA 短信）
- TerminalSettings（终端）
- RemindersSettings（提醒事项）
- ClaudeCodeSwitcherSettings + Claude Provider 数据 + MCP 服务器数据（Claude Code）

#### Scenario: 导出文件包含所有模块配置
- **WHEN** 用户点击「导出」按钮
- **THEN** 生成的 JSON 包含上述所有模块的配置字段，每个字段的值反映当前系统实际设置，其中 `mcpServers` 字段包含所有 MCP 服务器配置

#### Scenario: 导出包含 MCP 服务器完整配置
- **WHEN** 用户点击「导出」按钮
- **THEN** 生成的 JSON 中 `mcpServers` 数组包含每个 MCP 服务器的 id、name、serverConfig、description、homepage、docs、tags、isEnabled 字段

#### Scenario: 各模块配置独立存储
- **WHEN** 用户导入一个包含部分模块配置的备份文件（未来模块可能增减）
- **THEN** 系统对存在的模块配置进行恢复，不因缺少某个模块字段而失败

#### Scenario: 旧版备份缺少 mcpServers 字段
- **WHEN** 用户导入一个 v2.0 版本但不含 `mcpServers` 字段的备份文件
- **THEN** 系统正常导入其他配置，MCP 服务器列表保持不变（不覆盖为空）

### Requirement: 导入后触发全局刷新
导入完成后 SHALL 发送 `AppConfigDidImport` 通知、重新加载 SnippetService 内存数据、并同步 MCP 配置到 Claude Code。

#### Scenario: Snippet 数据重新加载
- **WHEN** 导入成功完成
- **THEN** SnippetService.shared 调用 reloadAfterImport() 刷新内存中的 snippet 数据

#### Scenario: 全局配置刷新通知
- **WHEN** 导入成功完成
- **THEN** 系统发送 `AppConfigDidImport` 通知，各功能模块监听并重新加载配置

#### Scenario: MCP 配置同步到 Claude Code
- **WHEN** 导入成功完成且备份文件包含 `mcpServers` 字段
- **THEN** 系统 SHALL 将还原的 MCP 服务器数据保存到 `mcp_servers.json`，并将所有已启用的 MCP 服务器同步写入 `~/.claude.json`
