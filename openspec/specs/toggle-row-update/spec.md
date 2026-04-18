## ADDED Requirements

### Requirement: Toggle 后就地更新行数据
Toggle Provider/MCP/Skill 后，系统 SHALL 直接修改 `results` 数组中对应行的 icon 和 displayAlias，而非调用 `loadClaudeCodeItems()` 重建整个列表。

#### Scenario: MCP toggle 后行更新
- **WHEN** 用户在 Claude Code Switcher 中按回车切换一个 MCP 服务器的启用状态
- **THEN** 该行的图标和 displayAlias 更新为反映新状态，tableView 只刷新该行，滚动位置不变

#### Scenario: Skill toggle 后行更新
- **WHEN** 用户按回车切换一个 Skill 的启用状态
- **THEN** 该行的图标和 displayAlias 更新为反映新状态，tableView 只刷新该行，滚动位置不变

#### Scenario: Provider 切换后双行更新
- **WHEN** 用户按回车切换到新的 Provider
- **THEN** 新 Provider 行更新为激活状态（绿色勾 + "当前"），旧 Provider 行更新为非激活状态（空心圆），tableView 刷新这两行，滚动位置不变

### Requirement: Toggle 后保持滚动位置
Toggle 操作后，tableView 的滚动位置 SHALL 保持不变。

#### Scenario: 连续 toggle 多个项目
- **WHEN** 用户在列表中滚动到中间位置后连续 toggle 多个 MCP/Skill
- **THEN** 每次 toggle 后列表的滚动位置都与 toggle 前一致，不回滚到顶部
