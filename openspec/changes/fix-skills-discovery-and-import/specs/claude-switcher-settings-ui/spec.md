## MODIFIED Requirements

### Requirement: Skills 工具栏导入按钮
SkillListView 的已安装 Tab 工具栏 SHALL 包含「从 Claude 导入」按钮。

#### Scenario: 已安装 Tab 显示导入按钮
- **WHEN** 用户在 Skills 设置页面选择「已安装」Tab
- **THEN** 工具栏右侧显示「从 Claude 导入」按钮，使用 `square.and.arrow.down` 图标

#### Scenario: 导入按钮与 MCP 一致
- **WHEN** 用户点击「从 Claude 导入」按钮
- **THEN** 导入行为与 MCP 设置页面的导入按钮交互一致
