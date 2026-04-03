## Context

LaunchX 搜索面板使用 AppKit 的 `NSTableView` + 自定义 `ResultCellView` 渲染搜索结果行。每个 cell 的布局根据项目类型动态切换：有路径的文件/文件夹使用 top 对齐 + 双行布局，App/WebLink 等使用 centerY 居中 + 单行布局。

搜索面板还支持多种扩展模式（IDE 项目、文件夹打开、网页直达 Query、实用工具、书签、2FA、Claude Code），每种模式通过独立的状态标志（`isInXXXMode`）管理，切换时需要先 `cleanupAllExtensionModes()` 再进入新模式。

### 当前问题

**问题 1：对齐不一致**
- `ResultCellView.configure()` 的垂直居中条件（第 414 行）缺少 `isClaudeCodeItem` 标志
- Claude Code 项目（Provider/MCP/Skills）走 else 分支 → `nameLabelTopConstraint` 激活 → 文字靠上，而图标始终 centerY → 视觉错位

**问题 2：竞态条件**
- `handleEnterClaudeCodeModeDirectly()` 使用 `DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)` 延迟执行
- 快速连续切换时，延迟任务在面板已被其他模式接管后执行，覆盖当前模式的状态

## Goals / Non-Goals

**Goals:**
- 修复 Provider 面板中非激活 Provider 行的图标和文字垂直对齐问题
- 修复通过快捷键快速切换扩展界面时的竞态条件
- 确保所有 Claude Code 项目（Provider、MCP、Skills）在搜索面板中具有一致的垂直居中布局

**Non-Goals:**
- 不重新设计 ResultCellView 的布局系统
- 不重构扩展模式的整体状态管理架构
- 不修改其他扩展模式（IDE、书签、2FA 等）的行为

## Decisions

### Decision 1: 在垂直居中条件中增加 `isClaudeCodeItem`

**选择**: 在 `ResultCellView.configure()` 的 if 条件中增加 `item.isClaudeCodeItem`

**理由**: Claude Code 项目在搜索面板中的表现形式（只有名称 + 可选的别名 badge，无路径）与 App/WebLink 等完全一致，应该使用相同的单行居中布局。

**备选方案**:
- 为 Claude Code 项目设置 `isWebLink = true` 或其他已有标志 → 语义不正确，`isWebLink` 有特定含义
- 增加 pathLabel 的隐藏逻辑 → 不彻底，nameLabel 对齐仍然是 top

### Decision 2: 移除 asyncAfter 延迟，改为同步执行

**选择**: 将 `handleEnterClaudeCodeModeDirectly()` 中的 `asyncAfter` 延迟改为同步执行

**理由**:
- 其他所有扩展模式（IDE、书签、2FA 等）的通知处理都是同步的
- `showPanel()` 本身也是同步的
- 延迟 0.1 秒没有实际意义，面板显示后模式应该立即生效
- 同步执行消除了竞态窗口

**流程对比**:
```
修复前:
  快捷键 → showPanel() → asyncAfter(0.1s) → enterClaudeCodeMode()
                                  ↑ 0.1秒窗口，其他事件可能介入

修复后:
  快捷键 → showPanel() → enterClaudeCodeMode()
                          ↑ 同步执行，无竞态窗口
```

**备选方案**:
- 使用标志位取消未执行的 asyncAfter → 增加复杂度，不如直接同步
- 使用 OperationQueue 取消 → 过度设计

## Risks / Trade-offs

- **[风险] 同步执行导致面板动画未完成时就开始渲染内容** → 影响极小，其他模式都是同步的且没有问题
- **[风险] 添加 isClaudeCodeItem 条件可能影响其他使用 ResultCellView 的场景** → 不会，因为 isClaudeCodeItem 仅在 Claude Code 模式下才为 true
