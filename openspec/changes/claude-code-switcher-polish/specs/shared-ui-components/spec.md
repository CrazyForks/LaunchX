## MODIFIED Requirements

### Requirement: ResultCellView Claude Code 活跃项图标颜色
ResultCellView 在渲染 Claude Code 活跃项时 SHALL 显示绿色状态图标，选中行时回退为白色。

#### Scenario: 未选中时显示绿色图标
- **WHEN** ResultCellView 渲染一个 Claude Code 活跃项（isClaudeCodeItem == true 且 path == "active"）
- **THEN** 图标（checkmark.circle.fill）的 contentTintColor 设为 NSColor.systemGreen

#### Scenario: 选中时回退白色图标
- **WHEN** ResultCellView 渲染一个 Claude Code 活跃项且行处于选中状态
- **THEN** 图标的 contentTintColor 设为 NSColor.white，与选中行整体白色风格一致

#### Scenario: 非活跃项不受影响
- **WHEN** ResultCellView 渲染一个 Claude Code 非活跃项（path != "active"）
- **THEN** 图标保持默认渲染，不应用特殊颜色
