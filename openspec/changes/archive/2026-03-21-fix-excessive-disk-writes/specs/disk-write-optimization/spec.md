## ADDED Requirements

### Requirement: 剪贴板保存防抖动
系统 SHALL 使用防抖动机制延迟保存剪贴板数据，以减少磁盘写入频率。

#### Scenario: 剪贴板变化后延迟保存
- **WHEN** 用户复制内容到剪贴板
- **THEN** 系统 MUST 在 2 秒后才保存剪贴板数据到磁盘
- **THEN** 系统 MUST 在这 2 秒内如果又有新的剪贴板变化，重置定时器
- **THEN** 系统 MUST 只保存最后一次变化的数据

#### Scenario: 多次剪贴板操作合并保存
- **WHEN** 用户在 2 秒内连续进行多次剪贴板操作（复制、粘贴、pin、delete）
- **THEN** 系统 MUST 只在最后一次操作完成后 2 秒保存一次
- **THEN** 系统 MUST 确保所有操作的结果都被正确保存

#### Scenario: 应用进入后台立即保存
- **WHEN** 应用即将进入后台
- **WHEN** 有未保存的剪贴板数据
- **THEN** 系统 MUST 立即保存剪贴板数据
- **THEN** 系统 MUST 取消待执行的延迟保存定时器

#### Scenario: 应用终止前保存
- **WHEN** 应用即将终止
- **WHEN** 有未保存的剪贴板数据
- **THEN** 系统 MUST 立即保存剪贴板数据
- **THEN** 系统 MUST 确保不丢失用户数据

### Requirement: 剪贴板检查频率优化
系统 SHALL 降低剪贴板检查频率以减少系统资源占用。

#### Scenario: 定期检查剪贴板变化
- **WHEN** 应用在运行
- **THEN** 系统 MUST 每 2.5 秒检查一次剪贴板变化
- **THEN** 系统 MUST 在检测到变化时触发保存流程

#### Scenario: 剪贴板监控暂停
- **WHEN** 用户在设置中禁用剪贴板功能
- **THEN** 系统 MUST 停止定时检查剪贴板
- **THEN** 系统 MUST 释放相关资源

### Requirement: SQLite WAL checkpoint 优化
系统 SHALL 调整 SQLite WAL checkpoint 阈值以减少磁盘写入频率。

#### Scenario: WAL checkpoint 阈值提升
- **WHEN** 系统初始化数据库连接
- **THEN** 系统 MUST 将 wal_autocheckpoint 设置为 10000 页
- **THEN** 系统 MUST 确保 WAL 文件在达到 10000 页时才自动 checkpoint

#### Scenario: 应用空闲时手动 checkpoint
- **WHEN** 应用空闲超过 5 分钟
- **WHEN** WAL 文件大小超过 10 MB
- **THEN** 系统 SHOULD 触发手动 checkpoint
- **THEN** 系统 MUST 在后台执行 checkpoint，不影响用户操作

#### Scenario: WAL 文件大小监控
- **WHEN** WAL 文件大小超过 100 MB
- **THEN** 系统 MUST 立即强制执行 checkpoint
- **THEN** 系统 MUST 记录警告日志

### Requirement: FSEvents 批量处理
系统 SHALL 批量处理文件系统事件以减少数据库写入次数。

#### Scenario: 短时间内事件批量处理
- **WHEN** 文件系统在 500ms 内产生多个变化事件
- **THEN** 系统 MUST 将这些事件收集到队列中
- **THEN** 系统 MUST 在 500ms 后使用单个数据库事务处理所有事件
- **THEN** 系统 MUST 确保所有事件都被正确处理

#### Scenario: 批量处理过程中的新事件
- **WHEN** 系统正在批量处理事件
- **WHEN** 又有新的文件系统事件产生
- **THEN** 系统 MUST 将新事件加入到下一批处理队列
- **THEN** 系统 MUST 不中断当前批次的处理

#### Scenario: 事件队列溢出保护
- **WHEN** FSEvents 队列中的事件超过 1000 个
- **THEN** 系统 MUST 立即处理当前队列
- **THEN** 系统 MUST 记录警告日志
- **THEN** 系统 MUST 考虑限制监控范围

### Requirement: 文件监控延迟启动
系统 SHALL 在应用完全启动后再启动文件系统监控。

#### Scenario: 延迟启动 FSEvents 监控
- **WHEN** 应用启动完成
- **WHEN** 文件索引加载完成
- **THEN** 系统 MUST 等待 5 秒后再启动 FSEvents 监控
- **THEN** 系统 MUST 确保启动过程不受影响

#### Scenario: 启动期间的事件处理
- **WHEN** FSEvents 监控尚未启动
- **WHEN** 文件系统发生变化
- **THEN** 系统 MAY 丢失这些事件
- **THEN** 系统 MUST 在下次完整扫描时捕获这些变化

### Requirement: 磁盘写入量监控
系统 SHALL 监控磁盘写入量并提供可视化统计。

#### Scenario: 实时写入量统计
- **WHEN** 系统执行磁盘写入操作
- **THEN** 系统 MUST 记录写入的字节数
- **THEN** 系统 MUST 计算平均写入速率（KB/s）

#### Scenario: 写入量警告
- **WHEN** 平均写入速率超过 80 KB/s
- **THEN** 系统 MUST 记录警告日志
- **THEN** 系统 MAY 显示通知提示用户

#### Scenario: 写入量统计展示
- **WHEN** 用户打开设置中的性能面板
- **THEN** 系统 MUST 显示当前的磁盘写入速率
- **THEN** 系统 MUST 显示历史写入量趋势图
- **THEN** 系统 MUST 显示各组件的写入量占比

### Requirement: 优化开关控制
系统 SHALL 提供独立的开关控制每个优化功能，便于调试和回滚。

#### Scenario: 禁用剪贴板防抖动
- **WHEN** 用户在设置中禁用剪贴板防抖动
- **THEN** 系统 MUST 立即保存剪贴板数据（不延迟）
- **THEN** 系统 MUST 记录设置变化

#### Scenario: 禁用 FSEvents 批量处理
- **WHEN** 用户在设置中禁用 FSEvents 批量处理
- **THEN** 系统 MUST 立即处理每个文件系统事件
- **THEN** 系统 MUST 不使用批量队列

#### Scenario: 禁用 WAL checkpoint 优化
- **WHEN** 用户在设置中禁用 WAL checkpoint 优化
- **THEN** 系统 MUST 使用默认的 WAL checkpoint 设置（1000 页）
- **THEN** 系统 MUST 在下次数据库初始化时生效

### Requirement: 性能影响最小化
系统 SHALL 确保优化不会影响用户体验和功能正确性。

#### Scenario: 剪贴板操作响应时间
- **WHEN** 用户进行剪贴板操作（复制、粘贴、pin）
- **THEN** 系统 MUST 在 100ms 内完成 UI 响应
- **THEN** 系统 MUST 不阻塞用户操作

#### Scenario: 文件索引准确性
- **WHEN** FSEvents 批量处理启用
- **THEN** 系统 MUST 确保文件索引的准确性不低于立即处理
- **THEN** 系统 MUST 正确处理所有文件系统事件

#### Scenario: 数据完整性保证
- **WHEN** 应用异常终止
- **THEN** 系统 MUST 确保剪贴板数据不丢失（最多丢失最后 2 秒的数据）
- **THEN** 系统 MUST 确保文件索引可以在下次启动时恢复
