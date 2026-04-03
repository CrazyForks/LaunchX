## ADDED Requirements

### Requirement: Remove Project from Recent List
系统 SHALL 允许用户从IDE的最近项目列表中移除项目记录,而不删除实际的项目文件。

#### Scenario: User removes project from recent list
- **WHEN** 用户在IDE扩展模式下选中一个项目并按⌘K打开快捷操作菜单
- **THEN** 系统显示"从最近列表移除"选项(不是"删除")

#### Scenario: Remove action only affects recent list
- **WHEN** 用户点击"从最近列表移除"选项
- **THEN** 系统仅从IDE的最近项目数据库中移除该项目记录,项目文件夹保持不变

#### Scenario: Project list refreshes after removal
- **WHEN** 项目从最近列表中移除成功后
- **THEN** 系统刷新IDE项目列表,被移除的项目不再显示

#### Scenario: Remove action works for all supported IDEs
- **WHEN** 用户在VSCode、Cursor、Zed、Antigravity或JetBrains IDE的最近项目列表中移除项目
- **THEN** 系统正确更新对应IDE的最近项目数据库

### Requirement: Safe Remove Operation
"从最近列表移除"操作 MUST 是安全的,不会导致数据丢失。

#### Scenario: Remove operation is non-destructive
- **WHEN** 用户执行"从最近列表移除"操作
- **THEN** 系统不删除、不移动、不修改实际的项目文件夹及其内容

#### Scenario: Remove operation can be undone by reopening project
- **WHEN** 用户从最近列表移除一个项目后
- **THEN** 用户可以通过在IDE中重新打开该项目来将其重新添加到最近列表

### Requirement: Quick Action Menu in IDE Extension Mode
IDE扩展模式下的快捷操作菜单 MUST 显示适当的操作选项。

#### Scenario: IDE project quick actions include remove option
- **WHEN** 用户在IDE扩展模式下按⌘K
- **THEN** 快捷操作菜单显示: cd至此、在Finder中显示、复制路径、从最近列表移除

#### Scenario: Remove option is not styled as destructive
- **WHEN** 快捷操作菜单显示"从最近列表移除"选项
- **THEN** 该选项不使用红色警示样式(因为不是破坏性操作)

#### Scenario: Separator appears before remove option
- **WHEN** 快捷操作菜单显示
- **THEN** 在"从最近列表移除"选项前显示分隔线

### Requirement: IDE-Specific Database Operations
系统 MUST 正确处理不同IDE的数据库格式。

#### Scenario: VSCode database is updated correctly
- **WHEN** 用户从VSCode最近列表移除项目
- **THEN** 系统更新`~/Library/Application Support/Code/User/globalStorage/state.vscdb`数据库

#### Scenario: Cursor database is updated correctly
- **WHEN** 用户从Cursor最近列表移除项目
- **THEN** 系统更新`~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`数据库

#### Scenario: Zed database is updated correctly
- **WHEN** 用户从Zed最近列表移除项目
- **THEN** 系统更新`~/Library/Application Support/Zed/db/0-stable/db.sqlite`数据库

#### Scenario: JetBrains database is updated correctly
- **WHEN** 用户从JetBrains IDE最近列表移除项目
- **THEN** 系统更新对应IDE的`~/Library/Application Support/JetBrains/<IDE>/options/recentProjects.xml`文件

### Requirement: User Feedback on Remove Operation
系统 SHALL 提供操作反馈,让用户知道移除操作已成功执行。

#### Scenario: Success message is shown after removal
- **WHEN** 项目从最近列表成功移除
- **THEN** 系统显示成功提示消息

#### Scenario: Error handling for database operations
- **WHEN** 数据库操作失败(如文件权限问题)
- **THEN** 系统显示错误提示,但不影响应用的其他功能
