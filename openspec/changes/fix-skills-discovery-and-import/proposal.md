## Why

Skills 发现功能存在两个 bug：1) 点击刷新后只显示第一个仓库的 skills，第二个仓库的结果丢失；2) 刷新过程中主线程被密集的串行网络请求占用，出现彩虹圈。此外，Skills 设置缺少 MCP 中已有的「从 Claude 导入」按钮，后端 `scanUnmanagedSkills()` 和 `importSkill()` 已就绪但没有 UI 入口。

## What Changes

- **修复多仓库发现**: `discoverSkills()` 中对每个仓库的 GitHub API 错误（如 403 限流）静默吞掉导致后续仓库被跳过；需要增加错误日志，同时调查第二个仓库结果丢失的根因
- **发现过程并行化**: 将仓库级别的 tree API 请求和 SKILL.md 内容下载改为并行（TaskGroup），大幅减少总耗时，避免主线程被串行回调密集占用
- **增量 UI 更新**: 发现过程中每完成一个仓库就更新一次 `discoveredSkills`，让用户看到渐进式加载而非等待全部完成
- **添加「从 Claude 导入」按钮**: 在 SkillListView 工具栏添加导入按钮，调用已有的 `scanUnmanagedSkills()` + `importSkill()` 导入 `~/.claude/skills/` 中未管理的 Skills

## Capabilities

### New Capabilities

（无新 capability）

### Modified Capabilities

- `claude-skills-management`: discoverSkills 需支持多仓库并行发现和增量更新；新增导入 UI 入口
- `claude-switcher-settings-ui`: SkillListView 工具栏新增导入按钮

## Impact

- **ClaudeSkillService.swift**: `discoverSkills()` 重构为并行 + 增量更新，增加错误日志
- **SkillListView.swift**: 工具栏添加「从 Claude 导入」按钮
- 现有 `scanUnmanagedSkills()` 和 `importSkill()` 方法无需修改，仅添加 UI 调用

### Rollback Plan

改动局限于 Skills 模块内部，不影响其他功能。如需回滚恢复改动文件即可。
