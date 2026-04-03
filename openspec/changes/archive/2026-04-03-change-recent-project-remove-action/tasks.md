# Implementation Tasks

## 1. 修改QuickActionType枚举

- [x] 1.1 在`LaunchX/Views/QuickActionsView.swift`中添加新的`.removeFromRecent` case到`QuickActionType`枚举
- [x] 1.2 为`.removeFromRecent`添加title属性,返回"从最近列表移除"
- [x] 1.3 为`.removeFromRecent`添加icon属性,使用合适的系统图标(如"xmark.circle")
- [x] 1.4 确认`.removeFromRecent`的isDestructive属性返回false

## 2. 实现IDERecentProjectsService移除功能

- [x] 2.1 在`LaunchX/Services/IDERecentProjectsService.swift`中添加`removeRecentProject(for:projectPath:)`公共方法
- [x] 2.2 实现`removeVSCodeRecentProject(projectPath:)`方法,更新VSCode的state.vscdb数据库
- [x] 2.3 实现`removeCursorRecentProject(projectPath:)`方法,更新Cursor的state.vscdb数据库
- [x] 2.4 实现`removeZedRecentProject(projectPath:)`方法,更新Zed的db.sqlite数据库
- [x] 2.5 实现`removeAntigravityRecentProject(projectPath:)`方法,更新Antigravity的state.vscdb数据库
- [x] 2.6 实现`removeJetBrainsRecentProject(for:projectPath:)`方法,更新JetBrains的recentProjects.xml文件

## 3. 更新SearchPanelViewController快捷操作逻辑

- [x] 3.1 在`LaunchX/Views/Search/SearchPanelViewController+Modes.swift`中修改`showQuickActions(for:)`方法,判断是否为IDE扩展模式
- [x] 3.2 为IDE扩展模式创建专用的actions数组,包含`[.openInTerminal, .showInFinder, .copyPath, .removeFromRecent]`
- [x] 3.3 在`executeQuickAction(_:)`方法中添加`.removeFromRecent` case处理
- [x] 3.4 实现`quickActionRemoveFromRecent(project:)`方法,调用IDERecentProjectsService移除项目
- [x] 3.5 在移除成功后刷新项目列表,更新`ideProjects`和`filteredIDEProjects`
- [x] 3.6 添加成功提示消息显示

## 4. 测试和验证

- [x] 4.1 测试VSCode最近项目移除功能
- [x] 4.2 测试Cursor最近项目移除功能
- [x] 4.3 测试Zed最近项目移除功能
- [x] 4.4 测试JetBrains IDE(IntelliJ/PyCharm等)最近项目移除功能
- [x] 4.5 验证移除操作不影响实际项目文件夹
- [x] 4.6 验证快捷操作菜单在IDE扩展模式下正确显示
- [x] 4.7 验证移除后项目列表正确刷新
- [x] 4.8 测试数据库操作失败时的错误处理

## 5. 代码清理和文档

- [x] 5.1 移除或注释掉原有的物理删除相关代码(如果不再需要)
- [x] 5.2 添加代码注释,说明新功能的用途
- [x] 5.3 更新相关文档(如有)

**注意**: 物理删除功能在非IDE模式下仍然保留,因为普通文件/文件夹的删除功能依然有用。只在IDE扩展模式下使用"从最近列表移除"操作.
