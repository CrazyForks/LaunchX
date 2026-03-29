## Context

LaunchX 是一款 macOS 原生启动器应用（SwiftUI + AppKit），当前版本 v0.3.2，具备应用搜索、文件索引、剪贴板管理、AI 翻译、书签搜索等功能。用户群体主要是 macOS 开发者。

当前 Claude Code 用户在切换 API Provider 时需要手动编辑 `~/.claude/settings.json`，管理 MCP 服务器需要编辑 `~/.claude.json`，安装 Skills 需要手动下载文件到 `~/.claude/skills/`。cc-switch 项目（Tauri + React + Rust）已经实现了这些功能，但需要额外安装独立应用。

本次设计的目标是将 cc-switch 中 **仅与 Claude Code 相关** 的功能移植到 LaunchX 中，作为启动器的一个高级扩展功能。

## Goals / Non-Goals

**Goals:**
- 在 LaunchX 中集成 Claude Code Provider 管理，支持添加、编辑、删除、切换 Provider
- 提供 20+ 内置 Provider 预设，用户只需填入 API Key 即可使用
- 实现 MCP 服务器管理，自动同步到 `~/.claude.json`
- 实现 Skills 发现与安装，从 GitHub 仓库浏览并同步到 `~/.claude/skills/`
- 首次使用时自动导入已有 Claude Code 配置
- 切换 Provider 前自动备份，支持回滚
- 遵循 LaunchX 现有的架构模式（MVVM + 服务层 + JSON 配置存储）

**Non-Goals:**
- 不支持 Codex、Gemini CLI、OpenCode、OpenClaw 等其他 CLI 工具
- 不实现代理模式（Proxy Takeover）、热切换等高级功能
- 不实现使用统计/成本追踪功能
- 不实现 Session/会话历史管理
- 不实现 Prompts 管理（CLAUDE.md 编辑）
- 不实现云同步功能
- 不实现 Deep Link 功能

## Decisions

### 1. 数据存储方案：JSON 文件而非 SQLite

**选择**：使用 JSON 文件存储 Provider、MCP、Skills 数据，存储路径为 `~/Library/Application Support/LaunchX/claude/`

**理由**：
- LaunchX 现有配置管理使用 JSON 文件（`~/Library/Application Support/LaunchX/config/`），保持一致性
- Claude Code 管理的数据量有限（通常几十个 Provider、几十个 MCP 服务器），JSON 文件足够
- 避免引入额外的 SQLite 数据库复杂度（现有 SQLite 仅用于文件索引）

**替代方案**：SQLite 数据库（cc-switch 的方案）—— 对 LaunchX 的使用场景过重

**文件结构**：
```
~/Library/Application Support/LaunchX/claude/
├── providers.json          # Provider 列表和当前激活状态
├── mcp_servers.json        # MCP 服务器配置
├── skills.json             # 已安装 Skills 列表
├── skill_repos.json        # Skills 仓库配置
└── backups/                # 配置备份目录
    └── settings_20260329_143022.json
```

### 2. 架构模式：遵循 LaunchX 现有的服务层模式

**选择**：使用 Service 单例 + SwiftUI ObservableObject 模式

**理由**：
- LaunchX 现有功能（AI 翻译、剪贴板、书签等）均采用 Service 单例模式
- 符合项目既有架构，降低学习成本和集成复杂度

**类结构**：
- `ClaudeProviderService` — Provider CRUD、切换、预设管理、配置文件读写
- `ClaudeMcpService` — MCP 服务器管理、同步到 `~/.claude.json`
- `ClaudeSkillService` — Skills 发现、安装、卸载、同步管理

### 3. Provider 切换流程

**选择**：直接写入 `~/.claude/settings.json`，切换前备份

**流程**：
```
1. 用户选择切换到 Provider B
2. 读取当前 ~/.claude/settings.json，保存到 Provider A 的配置中（backfill）
3. 备份当前 settings.json 到 backups/ 目录
4. 将 Provider B 的 settings_config 写入 ~/.claude/settings.json
5. 触发 MCP 同步（将 enabled 的 MCP 服务器写入 ~/.claude.json）
6. 触发 Skills 同步（将 enabled 的 Skills symlink 到 ~/.claude/skills/）
```

### 4. Skills 安装方式：优先 symlink

**选择**：使用 symlink 将 LaunchX 管理的 Skills 链接到 `~/.claude/skills/`，失败时 fallback 到文件复制

**理由**：
- symlink 方式下，卸载只需删除链接，不破坏源文件
- LaunchX 作为主副本存储位置：`~/Library/Application Support/LaunchX/claude/skills/`

### 5. UI 集成方式：作为高级扩展

**选择**：在设置页"高级扩展"中新增"Claude Code"入口，点击后进入独立管理面板

**理由**：
- LaunchX 的扩展功能（剪贴板、AI 翻译、书签搜索等）均作为高级扩展集成
- 保持与现有设置页面结构一致
- Claude Code 管理功能面向开发者用户，适合放在高级扩展中

### 6. Provider 预设数据：Swift 结构体 + JSON 预设文件

**选择**：预设数据以 JSON 文件形式内置在 Bundle 中，运行时加载

**理由**：
- 预设数据较多（20+），JSON 文件便于维护和更新
- 与 cc-switch 的 TypeScript 预设文件对应，便于同步更新

## Risks / Trade-offs

- **[配置文件竞态]** Claude Code 可能在 LaunchX 写入配置的同时修改配置文件 → 使用原子写入（先写临时文件再 rename）降低风险
- **[Claude Code 版本兼容]** Claude Code 的配置文件格式可能随版本变化 → 仅操作 `env` 字段和已知的安全字段，保留未知字段不被破坏
- **[Skills symlink 权限]** macOS 可能限制 symlink 创建 → fallback 到文件复制模式
- **[GitHub API 限流]** Skills 仓库浏览需要 GitHub API 调用 → 使用未认证 API（60次/小时限制），对于浏览场景足够
- **[JSON 文件并发]** 多个 Service 可能同时读写 JSON 文件 → 使用文件锁或串行化队列保护

## Migration Plan

1. 新增所有服务、模型、视图文件（纯新增，不修改现有文件）
2. 在 `SettingsView` 的高级扩展区域添加 Claude Code 入口
3. 在 `HotKeyService` 中不需要注册新快捷键（通过设置页访问）
4. 回滚方案：移除新增文件，删除设置页入口即可
