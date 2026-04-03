## MODIFIED Requirements

### Requirement: Claude Code Item Vertical Alignment
Claude Code 项目（Provider、MCP、Skills）在搜索面板 ResultCellView 中渲染时，图标和文字 MUST 垂直居中对齐，使用与 App、WebLink 等相同的单行居中布局。

#### Scenario: Provider item is vertically centered
- **WHEN** Claude Code Switcher 模式显示 Provider 列表项（非激活状态）
- **THEN** 图标和名称文字 MUST 垂直居中对齐，nameLabel 使用 14pt medium 字体

#### Scenario: Active provider item is vertically centered
- **WHEN** Claude Code Switcher 模式显示当前激活的 Provider 项
- **THEN** 图标、名称文字和"当前"badge MUST 垂直居中对齐

#### Scenario: MCP item is vertically centered
- **WHEN** Claude Code Switcher 模式显示 MCP 服务器列表项
- **THEN** 图标和名称文字 MUST 垂直居中对齐

#### Scenario: Skill item is vertically centered
- **WHEN** Claude Code Switcher 模式显示 Skill 列表项
- **THEN** 图标和名称文字 MUST 垂直居中对齐

#### Scenario: Non-ClaudeCode items unchanged
- **WHEN** 显示普通搜索结果（App、文件、文件夹等）
- **THEN** 布局行为与修改前完全一致，不受 Claude Code 对齐修复影响
