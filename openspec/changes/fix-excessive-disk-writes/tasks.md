## 1. 剪贴板保存优化（阶段 1）

- [x] 1.1 在 ClipboardService 中添加 scheduleSave() 防抖动方法
- [x] 1.2 添加 saveTimer: Timer? 属性
- [x] 1.3 修改 addItem() 方法，使用 scheduleSave() 替代 saveItems()
- [x] 1.4 修改 removeItem() 方法，使用 scheduleSave() 替代 saveItems()
- [x] 1.5 修改 removeItems() 方法，使用 scheduleSave() 替代 saveItems()
- [x] 1.6 修改 clearHistory() 方法，使用 scheduleSave() 替代 saveItems()
- [x] 1.7 修改 togglePin() 方法，使用 scheduleSave() 替代 saveItems()
- [x] 1.8 修改 moveItemToFront() 方法，使用 scheduleSave() 替代 saveItems()
- [x] 1.9 在 startMonitoring() 中调整 Timer 间隔从 1.0 秒改为 2.5 秒
- [x] 1.10 实现 applicationWillTerminate() 保存逻辑（在 AppDelegate 中）
- [x] 1.11 实现应用进入后台时的立即保存逻辑
- [x] 1.12 添加 UserDefaults 开关控制防抖动功能
- [ ] 1.13 测试频繁复制粘贴场景，验证数据完整性
- [ ] 1.14 测试应用崩溃场景，确认最多丢失 2 秒数据

## 2. SQLite WAL 优化（阶段 2）

- [x] 2.1 在 IndexDatabase.openDatabase() 中添加 wal_autocheckpoint PRAGMA 设置为 10000
- [x] 2.2 添加 WAL 文件大小监控方法
- [x] 2.3 实现 WAL 文件大小超过 100 MB 时强制 checkpoint 的逻辑
- [x] 2.4 实现应用空闲时（5 分钟）手动 checkpoint 的逻辑
- [x] 2.5 添加 checkpoint 事件日志记录
- [x] 2.6 添加 checkpoint 失败处理和重试逻辑
- [x] 2.7 添加 UserDefaults 开关控制 WAL checkpoint 优化
- [ ] 2.8 运行 24 小时测试，监控 WAL checkpoint 频率
- [ ] 2.9 测试 WAL 文件大小是否保持在合理范围（< 100 MB）

## 3. FSEvents 批量处理（阶段 3）

- [x] 3.1 在 SearchEngine 中添加 fsEventQueue: [FSEvent] 属性
- [x] 3.2 添加 fsEventTimer: Timer? 属性
- [x] 3.3 修改 handleFSEvents() 方法，收集事件到队列
- [x] 3.4 实现 processFSEventsBatch() 方法处理队列中的事件
- [x] 3.5 实现 500ms 延迟定时器触发批量处理
- [x] 3.6 添加事件队列溢出保护（超过 1000 个事件立即处理）
- [x] 3.7 实现批量处理中的数据库事务优化
- [x] 3.8 添加批量处理错误处理和日志记录
- [x] 3.9 添加 UserDefaults 开关控制 FSEvents 批量处理
- [ ] 3.10 测试创建大量文件场景，验证索引准确性
- [ ] 3.11 测试批量处理延迟（500ms）对用户的影响
- [ ] 3.12 测试事件队列溢出场景，验证保护机制

## 4. 启动和监控优化（阶段 4）

- [x] 4.1 在 SearchEngine.loadIndexInBatches() 完成后延迟 5 秒启动 FSEvents 监控
- [ ] 4.2 实现磁盘写入量统计功能
- [ ] 4.3 添加写入速率计算（KB/s）
- [ ] 4.4 实现写入量警告功能（超过 80 KB/s）
- [ ] 4.5 实现写入量限制功能（超过 100 KB/s 自动调整）
- [ ] 4.6 添加性能监控日志
- [ ] 4.7 在设置界面添加性能统计面板
- [ ] 4.8 显示索引大小、WAL 大小、checkpoint 次数等信息
- [ ] 4.9 显示健康度评分和优化建议
- [ ] 4.10 测试应用启动性能，确认无明显延迟
- [ ] 4.11 测试多次唤起应用场景，验证无卡死现象
- [ ] 4.12 运行 24 小时测试，监控总体写入量降低效果

## 5. 回滚和文档（阶段 5）

- [x] 5.1 创建 UserDefaults 配置类管理所有优化开关
- [x] 5.2 在设置界面添加优化开关控制面板
- [x] 5.3 实现每个优化的独立开关（防抖动、WAL、批量处理）
- [x] 5.4 添加详细的性能日志记录功能
- [ ] 5.5 编写优化效果的测试报告模板
- [ ] 5.6 编写回滚步骤文档
- [ ] 5.7 添加代码注释，说明每个优化的原理和权衡
- [ ] 5.8 创建性能对比测试（优化前后）
- [ ] 5.9 编写用户说明文档，解释优化的影响
- [ ] 5.10 实现 A/B 测试框架（可选，用于逐步推出）

## 6. 测试和验证（贯穿所有阶段）

- [ ] 6.1 单元测试：剪贴板防抖动机制
- [ ] 6.2 单元测试：WAL checkpoint 优化
- [ ] 6.3 单元测试：FSEvents 批量处理
- [ ] 6.4 集成测试：完整场景测试（复制粘贴 + 文件索引）
- [ ] 6.5 性能测试：24 小时运行测试
- [ ] 6.6 压力测试：大量文件变化场景
- [ ] 6.7 稳定性测试：应用崩溃恢复测试
- [ ] 6.8 回滚测试：验证每个优化可以独立禁用
- [ ] 6.9 用户体验测试：确认无明显性能下降
- [ ] 6.10 数据完整性测试：确认剪贴板和索引数据不丢失

## 7. 发布准备

- [ ] 7.1 代码审查和优化
- [ ] 7.2 更新 CHANGELOG.md
- [ ] 7.3 准备版本发布说明
- [ ] 7.4 编写迁移指南（如果需要）
- [ ] 7.5 设置遥测开关，收集实际使用数据
- [ ] 7.6 准备快速回滚方案
- [ ] 7.7 灰度发布策略（先小范围测试）
- [ ] 7.8 监控发布后的性能指标
