## Context

### 当前状态
LaunchX 是一个 macOS 快速启动工具，类似于 Raycast。目前存在严重的磁盘写入过度问题：

1. **剪贴板服务**（ClipboardService）：
   - 使用 Timer 每秒检查剪贴板变化
   - 每次变化立即保存整个 JSON 文件（几百个项目 × 1KB = 几百 KB）
   - 每次 pin/delete/move 操作都触发保存
   - 用户频繁复制粘贴时产生大量写入

2. **文件索引服务**（SearchEngine + IndexDatabase）：
   - SQLite 使用 WAL 模式（journal_mode=WAL）
   - 每个 FSEvent 都触发数据库写入
   - WAL 文件达到 1000 页时自动 checkpoint，合并到主库
   - 后台运行时持续监控文件系统变化
   - 应用唤起时可能触发大量积压事件的批量处理

3. **写入量统计**：
   - 19 小时内写入 8.6 GB（126 KB/s）
   - 95% 来自 SQLite WAL，5% 来自剪贴板 JSON
   - 超过 macOS 限制（99.42 KB/s）

### 约束条件
- 必须保证数据一致性（剪贴板历史不丢失、索引准确）
- 不能影响用户体验（响应速度、功能正常）
- 需要支持快速回滚
- 修改后的代码要易于维护

## Goals / Non-Goals

**Goals:**
1. 将磁盘写入量降低 60-75%（从 126 KB/s 到 30-50 KB/s）
2. 消除应用唤起时的卡死现象
3. 保持剪贴板历史和文件索引的数据完整性
4. 提供监控机制，帮助识别未来的写入问题

**Non-Goals:**
- 不改变数据模型或存储格式
- 不影响剪贴板和索引的核心功能
- 不重写整个架构（保持渐进式优化）

## Decisions

### 1. 剪贴板防抖动机制

**决策**：使用 Timer 延迟保存，合并多次操作

**方案**：
```swift
private var saveTimer: Timer?

private func scheduleSave() {
    saveTimer?.invalidate()
    saveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
        self?.saveItems()
    }
}
```

**理由**：
- 简单有效，易于实现
- 合并 2 秒内的所有操作，大幅减少保存次数
- 用户不太可能在 2 秒内连续进行多次需要立即保存的操作

**替代方案**：
- 使用 DispatchWorkItem：实现更复杂，但功能相同
- 批量队列：需要更多代码，增加复杂度

**权衡**：
- 最多延迟 2 秒保存数据
- 如果应用崩溃，可能丢失最后 2 秒的数据
- **缓解措施**：在应用进入后台时立即保存

### 2. 剪贴板检查频率调整

**决策**：从 1 秒改为 2.5 秒

**理由**：
- 用户通常不会在 2.5 秒内连续复制多次
- 减少 CPU 使用率和轮询开销
- 降低数据库写入频率

**替代方案**：
- 保持 1 秒：浪费资源
- 延长到 5 秒：响应太慢，用户体验差

### 3. SQLite WAL checkpoint 阈值调整

**决策**：将 wal_autocheckpoint 从 1000 提升到 10000

**方案**：
```swift
executeSQL("PRAGMA wal_autocheckpoint = 10000")
```

**理由**：
- 默认 1000 页（约 4 MB）太小，频繁 checkpoint
- 10000 页（约 40 MB）可以容纳更多写入，减少 checkpoint 频率 90%
- checkpoint 是昂贵的操作，需要大量磁盘 I/O

**替代方案**：
- 禁用 WAL（journal_mode=DELETE）：写入更少，但并发性能差
- 手动控制 checkpoint：增加复杂度，容易出错

**权衡**：
- WAL 文件可能更大（最多 40 MB）
- checkpoint 时需要更多时间，但频率大幅降低
- **缓解措施**：在应用空闲时触发 checkpoint

### 4. FSEvents 批量处理

**决策**：将 500ms 内的事件批量处理，使用单个事务

**方案**：
```swift
private var fsEventQueue: [FSEvent] = []
private var fsEventTimer: Timer?

private func handleFSEvents(_ events: [FSEventsMonitor.FSEvent]) {
    fsEventQueue.append(contentsOf: events)

    fsEventTimer?.invalidate()
    fsEventTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
        self?.processFSEventsBatch()
    }
}

private func processFSEventsBatch() {
    database.insertBatch(recordsFromEvents(fsEventQueue))
    fsEventQueue.removeAll()
}
```

**理由**：
- 合并短时间内的事件，减少事务次数
- 500ms 的延迟对用户不可见
- 大幅降低数据库写入频率

**替代方案**：
- 每个事件立即处理：写入过多
- 更长的延迟（如 2 秒）：可能影响索引实时性

### 5. 延迟启动文件监控

**决策**：在应用完全启动并显示面板后，再启动 FSEvents 监控

**方案**：
```swift
// 在 SearchEngine.loadIndexInBatches() 完成后
// 延迟 5 秒再调用 startMonitoring()
DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
    self.startMonitoring()
}
```

**理由**：
- 避免启动时的大量 I/O 操作
- 给系统时间稳定下来
- 减少唤起时的性能压力

**权衡**：
- 启动后 5 秒内的文件变化可能不会被监控
- **缓解措施**：这 5 秒内的变化会在下次完整扫描时捕获

## Risks / Trade-offs

### 风险 1：剪贴板数据丢失
**描述**：防抖动延迟可能导致应用崩溃时丢失最近 2 秒的数据

**缓解措施**：
- 在应用进入后台时立即保存
- 在应用终止前保存
- 添加 UserDefaults 标志，记录最后保存时间

### 风险 2：索引不同步
**描述**：FSEvents 批量处理可能导致文件索引短暂不同步

**缓解措施**：
- 批量处理延迟只有 500ms，用户不可见
- 定期（每小时）进行完整性检查
- 提供手动重建索引的功能

### 风险 3：WAL 文件过大
**描述**：提升 checkpoint 阈值可能导致 WAL 文件占用更多磁盘空间

**缓解措施**：
- 10000 页约 40 MB，对现代系统可接受
- 在应用空闲时手动触发 checkpoint
- 添加监控，如果 WAL 超过 100 MB，强制 checkpoint

### 风险 4：回滚困难
**描述**：多个优化同时实施，难以确定哪个导致问题

**缓解措施**：
- 每个优化都有独立的开关（UserDefaults 标志）
- 可以逐个禁用来定位问题
- 保留详细日志，记录每次写入

## Migration Plan

### 阶段 1：剪贴板优化（1-2 天）
1. 实现 scheduleSave() 防抖动机制
2. 修改所有调用 saveItems() 的地方
3. 调整 Timer 间隔为 2.5 秒
4. 添加后台保存逻辑
5. 测试：频繁复制粘贴，检查数据完整性

### 阶段 2：SQLite WAL 优化（1 天）
1. 调整 wal_autocheckpoint 为 10000
2. 添加 WAL 文件大小监控
3. 实现空闲时 checkpoint
4. 测试：运行 24 小时，检查写入量

### 阶段 3：FSEvents 批量处理（2-3 天）
1. 实现 fsEventQueue 和批量处理逻辑
2. 添加 500ms 延迟定时器
3. 优化事务逻辑
4. 测试：创建大量文件，检查索引准确性

### 阶段 4：启动优化（1 天）
1. 延迟 FSEvents 监控启动
2. 添加写入量统计
3. 优化启动流程
4. 测试：多次唤起应用，检查性能

### 阶段 5：监控和回滚（1 天）
1. 添加 UserDefaults 开关
2. 实现写入量日志
3. 添加性能监控面板
4. 编写回滚脚本

### 回滚策略
如果优化后出现问题：
1. 通过 UserDefaults 禁用特定优化
2. 提供设置界面，允许用户切换优化开关
3. 保留旧代码路径，条件编译
4. 在 1-2 个版本内收集反馈，稳定后移除旧代码

## Open Questions

1. **Q**: synchronous 模式应该用 FULL 还是 NORMAL？
   - **A**: 先保持 NORMAL，如果写入量仍然过高，考虑改为 OFF（需要测试数据安全性）

2. **Q**: 是否需要限制 FSEvents 监控的路径数量？
   - **A**: 先不限制，如果监控路径过多导致性能问题，再考虑限制

3. **Q**: 批量处理的延迟时间（剪贴板 2s，FSEvents 500ms）是否合适？
   - **A**: 先使用这些值，通过实际测试调整

4. **Q**: 是否需要实现增量保存剪贴板 JSON（只保存变化部分）？
   - **A**: 防抖动已经足够，增量保存增加复杂度，暂不需要
