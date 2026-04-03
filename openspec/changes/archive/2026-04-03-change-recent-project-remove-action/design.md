# Design: IDE Recent Project Remove Action

## Context

IDE扩展界面显示最近打开的项目列表,用户可以通过⌘K快捷键打开快捷操作菜单。当前"删除"选项会执行物理删除(将项目文件夹移到废纸篓)。

## Goals

1. 将"删除"操作改为"从最近列表移除"
2. 仅移除IDE最近项目记录,不删除实际文件
3. 揖供更安全的用户体验

## Architecture & Approach

### 敘方案选择

**选择方案:1: 修改现有QuickActionType枚举**

修改`QuickActionType`枚举,将`.delete`改为`.removeFromRecent`,并在IDE扩展模式下使用此操作类型。

**优点**:
- 复用现有的快捷操作框架
- 代码改动量小
- 逻辑清晰,易于理解

**缺点**:
- 需要判断当前是否在IDE扩展模式
- 枚举命名需要更通用

**选择方案,2: 为IDE项目创建专用的操作类型**

创建新的`IDEProjectActionType`枚举,专门用于IDE扩展模式。

**优点**:
- 类型更明确
- 不影响其他快捷操作

**缺点**:
- 需要创建新的视图和代理
- 代码改动量大

**最终选择**: 方案1 - 修改现有枚举

理由:
- 改动最小,复用现有代码
- 快捷操作框架已经很成熟
- 只需修改执行逻辑即可

## Technical Design

### 1. 修改QuickActionType枚举

**文件**: `LaunchX/Views/QuickActionsView.swift`

```swift
enum QuickActionType: Equatable {
    case openInTerminal
    case showInFinder
    case copyPath
    case airDrop
    case openURL
    case openInApp
    case openInReminders
    case delete  // 保留,但在IDE扩展模式下改为"从最近列表移除"
    case removeFromRecent  // 新增:从最近列表移除
}
```

### 2. 更新QuickActionType的显示文本

```swift
var title: String {
    switch self {
    // ... 其他case保持不变
    case .delete: return "删除"
    case .removeFromRecent: return "从最近列表移除"
    }
}

var isDestructive: Bool {
    return self == .delete  // 只有.delete是破坏性操作
}
```

### 3. 修改SearchPanelViewController中的快捷操作显示逻辑

**文件**: `LaunchX/Views/Search/SearchPanelViewController+Modes.swift`

修改`showQuickActions(for:)` 方法:

```swift
func showQuickActions(for item: SearchResult) {
    // ... 现有代码 ...

    if item.isIDEProjectMode {
        // IDE项目扩展模式:显示专门的快捷操作
        let actions: [QuickActionType] = [
            .openInTerminal, .showInFinder, .copyPath, .removeFromRecent
        ]
        let actionsView = QuickActionsView(actions: actions)
        // ... 其余代码不变
    } else {
        // 普通模式:保持原有逻辑
        let actions: [QuickActionType] = [
            .openInTerminal, .showInFinder, .copyPath, .airDrop, .delete,
        ]
        let actionsView = QuickActionsView(actions: actions)
        // ... 其余代码不变
    }
}
```

### 4. 添加从最近列表移除的执行逻辑

**文件**: `LaunchX/Views/Search/SearchPanelViewController+Modes.swift`

```swift
func executeQuickAction(_ action: QuickActionType) {
    guard let target = currentQuickActionTarget else { return }

    switch action {
    // ... 其他case保持不变
    case .removeFromRecent:
        quickActionRemoveFromRecent(project: target)
    }
}

func quickActionRemoveFromRecent(project: SearchResult) {
    hideQuickActions()

    guard let ideType = currentIDEType else { return }

    // 调用服务从IDE的最近项目列表中移除
    IDERecentProjectsService.shared.removeRecentProject(
        for: ideType,
        projectPath: project.path
    )

    // 刷新项目列表
    ideProjects = IDERecentProjectsService.shared.getRecentProjects(for: ideType, limit: 20)
    filteredIDEProjects = ideProjects
    results = ideProjects.map { $0.toSearchResult() }
    tableView.reloadData()

    // 显示成功提示
    showSuccessMessage("已从最近列表中移除")
}
```

### 5. 实现IDERecentProjectsService的移除方法

**文件**: `LaunchX/Services/IDERecentProjectsService.swift`

```swift
/// 从最近项目列表中移除指定项目
/// - Parameters:
///   - ideType: IDE类型
///   - projectPath: 项目路径
func removeRecentProject(for ideType: IDEType, projectPath: String) {
    switch ideType {
    case .vscode:
        removeVSCodeRecentProject(projectPath: projectPath)
    case .cursor:
        removeCursorRecentProject(projectPath: projectPath)
    case .zed:
        removeZedRecentProject(projectPath: projectPath)
    case .antigravity:
        removeAntigravityRecentProject(projectPath: projectPath)
    default:
        if ideType.isJetBrains {
            removeJetBrainsRecentProject(for: ideType, projectPath: projectPath)
        }
    }
}

// 针对每个IDE实现具体的移除逻辑
private func removeVSCodeRecentProject(projectPath: String) {
    let dbPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(
            "Library/Application Support/Code/User/globalStorage/state.vscdb"
        )
        .path

    guard FileManager.default.fileExists(atPath: dbPath) else { return }

    do {
        // 1. 读取当前数据
        let jsonString = try Self.runCommand(
            executablePath: "/usr/bin/sqlite3",
            arguments: [
                dbPath,
                "SELECT value FROM ItemTable WHERE key='history.recentlyOpenedPathsList';"
            ]
        )
        guard !jsonString.isEmpty else { return }

        // 2. 解析JSON
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var entries = json["entries"] as? [[String: Any]]
        else { return }

        // 3. 过滤掉要移除的项目
        let filteredEntries = entries.filter { entry in
            let path = extractPath(from: entry)
            return path != projectPath
        }

        // 4. 写回数据库
        var modifiedJson: [String: Any] = ["entries": filteredEntries]
        let modifiedData = try JSONSerialization.data(withJSONObject: modifiedJson)

        // 使用sqlite3更新数据
        let tmpPath = FileManager.default.temporaryDirectory.path
        let tmpFile = tmpPath.appendingPathComponent("modified.json")
        try modifiedData.write(to: tmpFile)
        let updateSQL = "UPDATE ItemTable SET value = readfile('\(tmpPath)/modified.json') WHERE key='history.recentlyOpenedPathsList';"

        try Self.runCommand(
            executablePath: "/usr/bin/sqlite3",
            arguments: [dbPath, updateSQL]
        )
    } catch {
        print("Failed to remove VSCode recent project: \(error)")
    }
}

// 类似地实现其他IDE的移除方法...
```

## Risks & Trade-offs

### 风险

1. **数据库操作风险**: 修改IDE的数据库可能导致数据损坏
   - **缓解**: 操作前备份,提供回滚机制

2. **用户体验变化**: 用户可能期望物理删除
   - **缓解**: 提供清晰的UI提示,说明这是列表移除操作

### 权衡

1. **安全性 vs 功能性**: 放弃物理删除功能,换取更安全的用户体验
   - 这是值得的权衡,因为物理删除风险太高

2. **代码复杂度**: 需要为每个IDE实现单独的移除逻辑
   - 接受这个复杂度,因为不同IDE的数据库结构不同

## Migration Plan

### 部署步骤

1. 编译并测试新代码
2. 验证移除功能在各IDE上正常工作
3. 确认不影响其他快捷操作

### 回滚策略

如果需要恢复物理删除:

1. 还原`QuickActionType`枚举,移除`.removeFromRecent`
2. 恢复`showQuickActions`中的原始逻辑
3. 删除`removeRecentProject`相关方法

## Open Questions

无
