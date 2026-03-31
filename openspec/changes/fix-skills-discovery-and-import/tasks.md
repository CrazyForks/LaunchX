## 1. 修复 discoverSkills 多仓库发现

- [x] 1.1 ClaudeSkillService.swift: 重构 `discoverSkills()` 方法，使用 `withTaskGroup(of:)` 并行请求所有仓库的 GitHub tree API，每个仓库独立处理
- [x] 1.2 ClaudeSkillService.swift: 在每个仓库的 tree 结果处理中，使用子 TaskGroup 并行下载所有 SKILL.md 内容
- [x] 1.3 ClaudeSkillService.swift: 每完成一个仓库就将其结果追加到 `discoveredSkills`（增量更新），使用 `@MainActor` 确保线程安全
- [x] 1.4 ClaudeSkillService.swift: 对 GitHub API 非 200 响应（特别是 403 限流）添加 `print()` 日志，包含仓库名和状态码

## 2. 添加「从 Claude 导入」按钮

- [x] 2.1 SkillListView.swift: 在已安装 Tab 的工具栏中添加「从 Claude 导入」按钮（`square.and.arrow.down` 图标），,位于 Tab Picker 右侧
- [x] 2.2 SkillListView.swift: 按钮点击时调用 `service.scanUnmanagedSkills()` + 循环 `service.importSkill()`，完成后刷新列表
