## ADDED Requirements

### Requirement: SQLite WAL checkpoint 优化
文件索引数据库 SHALL 使用优化的 WAL checkpoint 设置以减少磁盘写入频率。

#### Scenario: WAL checkpoint 阈值设置
- **WHEN** 系统初始化文件索引数据库
- **THEN** 系统 MUST 将 wal_autocheckpoint PRAGMA 设置为 10000
- **THEN** 系统 MUST 确保 WAL 文件在达到 10000 页时才自动执行 checkpoint
- **THEN** 系统 MUST 记录 checkpoint 事件到日志

#### Scenario: 应用空闲时手动 checkpoint
- **WHEN** 应用空闲超过 5 分钟
- **WHEN** WAL 文件大小超过 10 MB
- **THEN** 系统 SHOULD 触发手动 checkpoint
- **THEN** 系统 MUST 在后台执行 checkpoint
- **THEN** 系统 MUST 不阻塞用户操作

#### Scenario: WAL 文件大小监控
- **WHEN** WAL 文件大小超过 100 MB
- **THEN** 系统 MUST 立即强制执行 checkpoint
- **THEN** 系统 MUST 记录警告日志
- **THEN** 系统 MUST 通知用户（如果写入量持续过高）

#### Scenario: checkpoint 失败处理
- **WHEN** checkpoint 操作失败
- **THEN** 系统 MUST 记录错误日志
- **THEN** 系统 MUST 继续正常操作
- **THEN** 系统 MUST 在下次合适时机重试 checkpoint

### Requirement: FSEvents 批量处理
系统 SHALL 批量处理文件系统事件以减少数据库写入次数。

#### Scenario: 短时间内事件收集
- **WHEN** 文件系统在 500ms 内产生多个变化事件（创建、删除、修改）
- **THEN** 系统 MUST 将这些事件收集到内存队列中
- **THEN** 系统 MUST 在 500ms 后使用单个数据库事务处理所有事件
- **THEN** 系统 MUST 确保所有事件都被正确处理

#### Scenario: 批量处理中的数据库事务
- **WHEN** 系统批量处理文件系统事件
- **THEN** 系统 MUST 开启单个数据库事务
- **THEN** 系统 MUST 处理队列中的所有事件（创建、删除、更新记录）
- **THEN** 系统 MUST 在处理完所有事件后提交事务
- **THEN** 系统 MUST 清空事件队列

#### Scenario: 批量处理过程中的新事件
- **WHEN** 系统正在批量处理事件
- **WHEN** 又有新的文件系统事件产生
- **THEN** 系统 MUST 将新事件加入到下一批处理队列
- **THEN** 系统 MUST 不中断当前批次的处理
- **THEN** 系统 MUST 在下一批次中处理新事件

#### Scenario: 事件队列溢出保护
- **WHEN** FSEvents 队列中的事件超过 1000 个
- **THEN** 系统 MUST 立即处理当前队列中的所有事件
- **THEN** 系统 MUST 记录警告日志
- **THEN** 系统 MUST 考虑限制监控范围或调整批量处理间隔

#### Scenario: 批量处理错误处理
- **WHEN** 批量处理过程中某个事件处理失败
- **THEN** 系统 MUST 记录失败事件的详细信息
- **THEN** 系统 MUST 继续处理队列中的其他事件
- **THEN** 系统 MUST 在下次完整扫描时修复失败的事件

### Requirement: 文件监控延迟启动
系统 SHALL 在应用完全启动并初始化完成后再启动文件系统监控。

#### Scenario: 延迟启动 FSEvents 监控
- **WHEN** 应用启动完成
- **WHEN** 文件索引加载到内存
- **WHEN** 搜索引擎准备就绪
- **THEN** 系统 MUST 等待 5 秒后再启动 FSEvents 监控
- **THEN** 系统 MUST 确保启动过程不受文件系统监控影响

#### Scenario: 启动期间的事件处理
- **WHEN** FSEvents 监控尚未启动
- **WHEN** 文件系统发生变化
- **THEN** 系统 MAY 丢失这些事件
- **THEN** 系统 MUST 在下次完整扫描或增量更新时捕获这些变化
- **THEN** 系统 MUST 确保最终索引准确性

#### Scenario: 文件监控重启
- **WHEN** 用户修改搜索范围配置
- **THEN** 系统 MUST 停止当前的 FSEvents 监控
- **THEN** 系统 MUST 更新监控路径列表
- **THEN** 系统 MUST 重新启动 FSEvents 监控
- **THEN** 系统 MUST 确保无缝切换

### Requirement: 批量插入优化
文件索引器 SHALL 使用批量插入以减少数据库事务次数。

#### Scenario: 批量插入文件记录
- **WHEN** 系统扫描文件系统构建索引
- **THEN** 系统 MUST 收集 1000 个文件记录
- **THEN** 系统 MUST 使用单个数据库事务插入这 1000 条记录
- **THEN** 系统 MUST 在达到 1000 条后立即插入并清空批次
- **THEN** 系统 MUST 在扫描结束时插入剩余的记录

#### Scenario: 批量插入性能监控
- **WHEN** 系统执行批量插入操作
- **THEN** 系统 MUST 记录每批次插入的耗时
- **THEN** 系统 MUST 记录插入速率（记录/秒）
- **THEN** 系统 MUST 在耗时异常时记录警告日志

#### Scenario: 批量插入错误处理
- **WHEN** 批量插入过程中某个记录插入失败
- **THEN** 系统 MUST 记录失败记录的详细信息
- **THEN** 系统 MUST 继续插入批次中的其他记录
- **THEN** 系统 MUST 在批次结束后报告失败记录数

### Requirement: 索引更新频率控制
系统 SHALL 控制索引更新频率以平衡实时性和性能。

#### Scenario: 增量更新节流
- **WHEN** 文件系统在短时间内产生大量变化
- **THEN** 系统 MUST 批量处理这些变化（最多 500ms 延迟）
- **THEN** 系统 MUST 确保索引在 1 秒内反映所有变化
- **THEN** 系统 MUST 不阻塞用户操作

#### Scenario: 定期完整性检查
- **WHEN** 系统运行超过 1 小时
- **THEN** 系统 SHOULD 执行轻量级完整性检查
- **THEN** 系统 MUST 随机抽查 100 个路径的存在性
- **THEN** 系统 MUST 删除不存在的路径
- **THEN** 系统 MUST 记录检查结果

#### Scenario: 手动重建索引
- **WHEN** 用户请求重建索引
- **THEN** 系统 MUST 停止 FSEvents 监控
- **THEN** 系统 MUST 清空现有索引
- **THEN** 系统 MUST 重新扫描所有配置的路径
- **THEN** 系统 MUST 在重建完成后恢复 FSEvents 监控

### Requirement: 磁盘写入量监控和限制
系统 SHALL 监控索引相关的磁盘写入量并提供限制机制。

#### Scenario: 实时写入量统计
- **WHEN** 系统执行索引相关的磁盘写入
- **THEN** 系统 MUST 记录写入的字节数
- **THEN** 系统 MUST 计算平均写入速率（KB/s）
- **THEN** 系统 MUST 区分 WAL 写入和 checkpoint 写入

#### Scenario: 写入量警告
- **WHEN** 索引相关的平均写入速率超过 80 KB/s
- **THEN** 系统 MUST 记录警告日志
- **THEN** 系统 MAY 显示通知提示用户
- **THEN** 系统 MUST 自动调整批量处理参数

#### Scenario: 写入量限制
- **WHEN** 索引相关的写入速率超过 100 KB/s 持续 1 分钟
- **THEN** 系统 MUST 临时降低 FSEvents 处理频率
- **THEN** 系统 MUST 增加批量处理延迟到 1 秒
- **THEN** 系统 MUST 记录限制事件
- **THEN** 系统 MUST 在速率降低后恢复正常设置

### Requirement: 索引性能指标
系统 SHALL 收集和报告索引性能指标。

#### Scenario: 索引大小统计
- **WHEN** 系统完成索引构建或更新
- **THEN** 系统 MUST 记录索引中的记录总数
- **THEN** 系统 MUST 记录数据库文件大小
- **THEN** 系统 MUST 记录 WAL 文件大小
- **THEN** 系统 MUST 在设置界面显示这些信息

#### Scenario: 索引性能统计
- **WHEN** 用户查看索引性能面板
- **THEN** 系统 MUST 显示最近的 checkpoint 次数和时间
- **THEN** 系统 MUST 显示平均写入速率
- **THEN** 系统 MUST 显示 FSEvents 处理次数
- **THEN** 系统 MUST 显示批量处理的批次大小

#### Scenario: 索引健康度评估
- **WHEN** 系统计算索引健康度
- **THEN** 系统 MUST 基于 checkpoint 频率、写入速率、WAL 大小评估
- **THEN** 系统 MUST 显示健康度评分（优秀/良好/警告/危险）
- **THEN** 系统 MUST 在健康度低时提供优化建议
