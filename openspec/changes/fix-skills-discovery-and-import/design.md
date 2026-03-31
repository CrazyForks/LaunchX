## Context

`discoverSkills()` 当前实现为串行遍历所有仓库，每个仓库串行下载所有 SKILL.md 内容。类标记 `@MainActor`，所有 await 回调回到主线程。当仓库数量多或 SKILL.md 文件多时，主线程被密集回调占用导致 UI 无响应。

当前错误处理使用 `continue` 静默跳过所有失败（网络错误、非 200 状态码、JSON 解析失败），用户无任何反馈。

Skills 导入功能的后端已完整（`scanUnmanagedSkills()` + `importSkill()`），但缺少 UI 入口。MCP 设置中有类似按钮可参考。

## Goals / Non-Goals

**Goals:**
- 修复多仓库发现只显示第一个仓库结果的问题
- 消除发现过程中的主线程阻塞（彩虹圈）
- 在 Skills 工具栏添加「从 Claude 导入」按钮

**Non-Goals:**
- 不重新设计发现 UI（不增加搜索、过滤等功能）
- 不修改 GitHub API 的认证方式（不添加 Token 支持）
- 不修改 `scanUnmanagedSkills()` / `importSkill()` 的实现

## Decisions

### D1: 多仓库发现 — 并行 TaskGroup

**选择**: 使用 `withTaskGroup(of:)` 并行请求所有仓库的 tree API
**替代方案**: 保持串行但添加错误提示
**理由**: 并行可将 N 个仓库的总耗时从 O(N) 降为 O(1)，同时减少主线程占用时间。每个仓库的 tree API 请求独立，无数据依赖。

```
当前 (串行):
Repo1 tree ──▶ SKILL.md #1 ──▶ #2 ──▶ ... ──▶ Repo2 tree ──▶ #1 ──▶ ...
总耗时 = sum(all requests)

改后 (并行仓库, 并行内容):
Repo1 tree ──▶┐                    ┌──▶ SKILL.md #1 ──▶┐
Repo2 tree ──▶┤  并行  ──────────▶│──▶ SKILL.md #2 ──▶│ 合并结果
              └───────────────────└──▶ ...            ┘
总耗时 ≈ max(repo_tree) + max(skill_content_per_repo)
```

### D2: SKILL.md 内容下载 — 仓库内并行

**选择**: 同一仓库内的 SKILL.md 下载也用 TaskGroup 并行
**理由**: 单个仓库可能有多个 SKILL.md，串行下载浪费时间。但需注意 GitHub raw content 的并发限制，避免过多并发请求。建议使用 `maxConcurrentTasks` 限制并发数。

### D3: 增量 UI 更新

**选择**: 每完成一个仓库就追加到 `discoveredSkills`
**替代方案**: 全部完成后一次性更新
**理由**: 用户可以看到渐进式加载效果，而非长时间空白等待。实现方式：在每个仓库的 TaskGroup 子任务完成后，将结果 append 到 `discoveredSkills`（@Published）。

### D4: 错误日志

**选择**: 对 GitHub API 非 200 响应打印警告日志（含仓库名、状态码）
**理由**: 当前静默 `continue` 导致问题难以排查。添加日志不改变行为，但帮助诊断。对于 403 限流，可在日志中特别提示。

### D5: 「从 Claude 导入」— MCP 简单模式

**选择**: 一个按钮调用 `scanUnmanagedSkills()`，遍历结果逐个 `importSkill()`，完成后显示导入数量
**替代方案**: 弹出 sheet 展示列表让用户勾选
**理由**: 与 MCP 的导入交互保持一致（简单按钮 + 静默导入），降低实现复杂度。未来可升级为交互模式。

## Risks / Trade-offs

- **[GitHub API 限流]** → 并行请求会加速消耗限额，但总量不变（每个 SKILL.md 仍需一次请求）。可后续考虑缓存或 Token 认证
- **[并发请求过多]** → 使用 TaskGroup 的并发限制控制同时请求数，避免被 GitHub 封 IP
- **[导入按钮无确认]** → 与 MCP 行为一致，直接导入所有未管理 Skills。如果用户不希望导入某个，可以在列表中禁用
