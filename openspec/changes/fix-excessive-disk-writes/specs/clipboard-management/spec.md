## ADDED Requirements

### Requirement: 剪贴板数据持久化延迟保存
剪贴板数据 SHALL 使用延迟保存机制以减少磁盘写入频率。

#### Scenario: 添加剪贴板项延迟保存
- **WHEN** 用户复制新内容到剪贴板
- **THEN** 系统 MUST 将新项添加到内存中的剪贴板历史
- **THEN** 系统 MUST 启动 2 秒延迟定时器
- **THEN** 系统 MUST 在定时器触发时将整个剪贴板历史保存到磁盘

#### Scenario: 多次操作合并保存
- **WHEN** 用户在 2 秒内连续添加多个剪贴板项
- **THEN** 系统 MUST 重置延迟定时器
- **THEN** 系统 MUST 只在最后一次操作后 2 秒保存
- **THEN** 系统 MUST 确保所有剪贴板项都被保存

#### Scenario: 删除操作延迟保存
- **WHEN** 用户删除剪贴板历史项
- **THEN** 系统 MUST 从内存中移除该项
- **THEN** 系统 MUST 启动 2 秒延迟定时器
- **THEN** 系统 MUST 在定时器触发时保存更新后的历史

#### Scenario: 固定操作延迟保存
- **WHEN** 用户切换剪贴板项的固定状态
- **THEN** 系统 MUST 更新内存中的固定状态
- **THEN** 系统 MUST 启动 2 秒延迟定时器
- **THEN** 系统 MUST 在定时器触发时保存更新后的历史

#### Scenario: 粘贴操作延迟保存
- **WHEN** 用户从剪贴板历史粘贴内容
- **THEN** 系统 MUST 更新该项的访问时间
- **THEN** 系统 MUST 将该项移动到历史顶部
- **THEN** 系统 MUST 启动 2 秒延迟定时器
- **THEN** 系统 MUST 在定时器触发时保存更新后的历史

#### Scenario: 应用后台时立即保存
- **WHEN** 应用即将进入后台
- **WHEN** 有未保存的剪贴板数据变更
- **THEN** 系统 MUST 立即保存剪贴板历史到磁盘
- **THEN** 系统 MUST 取消待执行的延迟定时器
- **THEN** 系统 MUST 确保数据不丢失

#### Scenario: 应用终止前保存
- **WHEN** 应用收到终止信号
- **WHEN** 有未保存的剪贴板数据变更
- **THEN** 系统 MUST 立即保存剪贴板历史到磁盘
- **THEN** 系统 MUST 优先保证数据完整性

### Requirement: 剪贴板监控频率优化
剪贴板监控 SHALL 降低检查频率以减少系统资源占用。

#### Scenario: 定期检查剪贴板变化
- **WHEN** 剪贴板监控处于活动状态
- **THEN** 系统 MUST 每 2.5 秒检查一次剪贴板变化
- **THEN** 系统 MUST 检测剪贴板的 changeCount 属性
- **THEN** 系统 MUST 在变化时触发保存流程

#### Scenario: 剪贴板监控启动
- **WHEN** 应用启动
- **WHEN** 剪贴板功能在设置中已启用
- **THEN** 系统 MUST 自动启动剪贴板监控
- **THEN** 系统 MUST 创建 2.5 秒间隔的定时器

#### Scenario: 剪贴板监控停止
- **WHEN** 用户在设置中禁用剪贴板功能
- **THEN** 系统 MUST 停止定时器
- **THEN** 系统 MUST 释放监控资源
- **THEN** 系统 MUST 不再检查剪贴板变化

## MODIFIED Requirements

### Requirement: 剪贴板写入逻辑
系统 SHALL 根据 asPlainText 参数决定写入剪贴板的内容格式。

#### Scenario: 粘贴后更新访问时间
- **WHEN** 用户粘贴剪贴板项（保留格式或纯文本）
- **THEN** 系统 MUST 更新该项的访问时间为当前时间
- **THEN** 系统 MUST 将该项移动到剪贴板历史顶部
- **THEN** 系统 MUST 启动延迟保存（2 秒后保存更新后的历史）
- **THEN** 系统 MUST 立即执行粘贴操作

### Requirement: 剪贴板数据模型扩展
ClipboardItem 数据模型 SHALL 支持存储富文本格式数据。

#### Scenario: 延迟保存富文本内容
- **WHEN** 系统检测到剪贴板中有富文本内容
- **THEN** 系统 MUST 立即解析并创建 ClipboardItem（包含所有格式）
- **THEN** 系统 MUST 将项添加到内存中的历史
- **THEN** 系统 MUST 启动 2 秒延迟定时器
- **THEN** 系统 MUST 在定时器触发时保存到磁盘

#### Scenario: 图片延迟保存
- **WHEN** 剪贴板项包含图片数据
- **THEN** 系统 MUST 立即将图片数据保存到磁盘的图片目录
- **THEN** 系统 MUST 在内存中保存图片的元数据（不包含实际图片数据）
- **THEN** 系统 MUST 启动 2 秒延迟定时器保存剪贴板历史 JSON
- **THEN** 系统 MUST 确保图片文件和历史 JSON 都被正确保存
