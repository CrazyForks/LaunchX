## Why

LaunchX 在后台运行 19 小时内产生了 8.6 GB 的磁盘写入（平均 126 KB/s），超过了 macOS 的磁盘写入限制（99.42 KB/s），导致系统性能警告和用户体验下降。这个问题主要由两个过度写入的场景造成：

1. **SQLite WAL 持续写入**（95%）：文件索引数据库使用 WAL 模式，每次文件系统变化都触发数据库写入
2. **剪贴板频繁保存**（5%）：每次剪贴板变化都完整保存 JSON 文件（几百个项目）

## What Changes

### 优先级 1：剪贴板保存优化
- **防抖动机制**：剪贴板变化后延迟 2 秒再保存，合并多次操作
- **批量操作优化**：连续的 pin/delete/move 操作只保存一次
- **降低检查频率**：将剪贴板检查间隔从 1 秒调整为 2-3 秒

### 优先级 2：SQLite WAL 优化
- **调整 WAL checkpoint 阈值**：从默认 1000 页提升到 10000 页，减少 checkpoint 频率
- **优化 synchronous 模式**：从 NORMAL 改为 FULL（更安全）或 OFF（更快，但需评估）
- **批量处理 FSEvents**：将短时间内的大量文件系统事件批量处理，减少数据库事务次数

### 优先级 3：启动和监控优化
- **延迟启动文件监控**：在应用完全启动后再开始 FSEvents 监控
- **限制 FSEvents 范围**：根据用户配置的搜索范围动态调整监控路径
- **添加写入监控**：添加磁盘写入量统计，帮助识别异常写入行为

**BREAKING**: 无破坏性变更，所有优化向后兼容

## Capabilities

### New Capabilities
- `disk-write-optimization`: 磁盘写入优化能力，涵盖剪贴板和数据库的写入优化策略

### Modified Capabilities
- `clipboard-history`: 剪贴板历史保存机制优化，从每次立即保存改为防抖动批量保存
- `file-indexing`: 文件索引的数据库写入优化，添加批量处理和 WAL 调优

## Impact

### 受影响的组件
- **ClipboardService.swift**: 添加防抖动机制，修改保存逻辑
- **IndexDatabase.swift**: 调整 SQLite WAL 参数
- **SearchEngine.swift**: 优化 FSEvents 处理，添加批量处理
- **FileIndexer.swift**: 可能需要调整批量插入逻辑

### 依赖和系统
- **SQLite**: 使用现有 SQLite3 库，仅调整 PRAGMA 参数
- **FSEvents API**: 保持使用现有 FSEventsMonitor，仅优化处理逻辑
- **macacos 磁盘 I/O**: 预期减少 60-80% 的磁盘写入量

### 回滚计划
如果优化后出现功能问题（如剪贴板数据丢失、索引不同步），可以：
1. 通过设置快速回滚到旧的保存逻辑
2. 恢复 SQLite WAL 参数到默认值
3. 禁用 FSEvents 批量处理功能

### 预期效果
- 磁盘写入量从 126 KB/s 降低到 30-50 KB/s（降低 60-75%）
- 剪贴板保存操作减少 70-90%
- 数据库 WAL checkpoint 频率降低 90%
- 用户体验改善：无卡死现象，系统资源占用降低
