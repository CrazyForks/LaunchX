## Why

在IDE扩展界面中,用户按⌘K会显示快捷操作菜单,其中最下方是"删除"选项。当前这个删除操作是物理删除,会直接将项目文件夹移到废纸篓。但用户通常只是想从最近项目列表中移除该项目记录,而不是删除实际的项目文件。物理删除操作过于危险,容易造成数据丢失。

## What Changes

- 修改IDE项目扩展模式下⌘K快捷菜单中的"删除"操作
- 将原来的物理删除改为"从最近项目列表中移除"
- 移除操作仅删除IDE的最近项目记录,不影响实际项目文件
- 保留分隔线样式,但移除红色警示外观(因为不再是破坏性操作)

## Capabilities

### New Capabilities
- `ide-recent-project-management`: IDE最近项目管理功能,支持从最近列表中移除项目记录

### Modified Capabilities
- `shared-ui-components`: 修改QuickActionsView,新增"从最近列表移除"操作类型

## Impact

- 影响文件:
  - `LaunchX/Views/QuickActionsView.swift` - 新增`.removeFromRecent`操作类型
  - `LaunchX/Views/Search/SearchPanelViewController+Modes.swift` - 修改快捷操作执行逻辑
  - `LaunchX/Services/IDERecentProjectsService.swift` - 新增从最近列表移除项目的方法
- 用户影响: IDE扩展模式下的删除操作将变为安全的列表管理操作
- 回滚计划: 如需恢复物理删除,可还原QuickActionType枚举和对应的执行逻辑
