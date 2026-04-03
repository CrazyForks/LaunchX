## ADDED Requirements

### Requirement: Remove from Recent List Action Type
QuickActionsView SHALL 支持新的"从最近列表移除"操作类型。

#### Scenario: RemoveFromRecent action type is available
- **WHEN** QuickActionType枚举被访问
- **THEN** 包含`.removeFromRecent` case

#### Scenario: RemoveFromRecent displays correct title
- **WHEN** `.removeFromRecent`的title属性被访问
- **THEN** 返回"从最近列表移除"

#### Scenario: RemoveFromRecent displays appropriate icon
- **WHEN** `.removeFromRecent`的icon属性被访问
- **THEN** 返回合适的系统图标(如"xmark.circle"或类似图标)

#### Scenario: RemoveFromRecent is not destructive
- **WHEN** `.removeFromRecent`的isDestructive属性被访问
- **THEN** 返回false(不使用红色警示样式)

### Requirement: Context-Aware Quick Actions
QuickActionsView MUST 根据上下文显示适当的快捷操作。

#### Scenario: IDE extension mode shows remove action
- **WHEN** 在IDE扩展模式下显示快捷操作
- **THEN** 显示".removeFromRecent"而不是".delete"

#### Scenario: Normal mode shows delete action
- **WHEN** 在普通文件浏览模式下显示快捷操作
- **THEN** 显示".delete"操作

#### Scenario: Quick actions preserve separator before destructive or removal actions
- **WHEN** 快捷操作菜单显示
- **THEN** 在删除或移除操作前显示分隔线
