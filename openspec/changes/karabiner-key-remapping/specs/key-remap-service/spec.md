## ADDED Requirements

### Requirement: 检测辅助功能权限
系统 SHALL 通过 `AXIsProcessTrusted()` 检测当前应用是否拥有辅助功能权限。未授权时 SHALL 返回 `false`。

#### Scenario: 已授权辅助功能权限
- **WHEN** 用户已在系统设置中授予 LaunchX 辅助功能权限
- **THEN** 系统 SHALL 返回权限状态为 `true`

#### Scenario: 未授权辅助功能权限
- **WHEN** 用户未授予 LaunchX 辅助功能权限
- **THEN** 系统 SHALL 返回权限状态为 `false`

### Requirement: 创建 CGEventTap 事件监听
系统 SHALL 在拥有辅助功能权限时创建 CGEventTap 监听键盘事件。事件监听 SHALL 在主线程 RunLoop 中运行。

#### Scenario: 成功创建 EventTap
- **WHEN** 辅助功能权限已授予
- **THEN** 系统 SHALL 创建 CGEventTap 并启用，开始监听 keyDown、keyUp、flagsChanged 事件

#### Scenario: 权限不足时创建失败
- **WHEN** 辅助功能权限未授予
- **THEN** 系统 SHALL 不创建 EventTap，Hyper 键和引号互换功能不可用

### Requirement: Caps Lock ↔ Control 互换（IOKit 原生）
系统 SHALL 通过 IOKit 的 `IORegistryEntrySetCFProperty` 设置 `UserKeyMapping` 属性来实现 Caps Lock 和 Left Control 的双向互换。此映射为内核级，零延迟，无需辅助功能权限。

#### Scenario: 启用 Caps ↔ Control 互换
- **WHEN** 用户勾选 Caps↔Control 互换选项
- **THEN** 系统 SHALL 遍历所有键盘设备，设置 UserKeyMapping：Caps Lock(0x70000039) ↔ Left Control(0x700000E0)

#### Scenario: 禁用 Caps ↔ Control 互换
- **WHEN** 用户取消勾选 Caps↔Control 互换选项
- **THEN** 系统 SHALL 遍历所有键盘设备，设置空 UserKeyMapping 数组恢复默认

#### Scenario: 映射在系统级生效
- **WHEN** Caps↔Control 互换已启用
- **THEN** 映射 SHALL 在系统级生效，即使 LaunchX 退出后仍有效（直到禁用或系统重启）

### Requirement: Hyper 键映射（CGEventTap）
系统 SHALL 通过 CGEventTap 将 Right Command 映射为 Hyper 键（Ctrl+Cmd+Shift+Option 同时按下）。系统 SHALL 正确追踪按键状态，长按时不重复发送修饰键事件。

#### Scenario: 启用 Hyper 键
- **WHEN** 用户勾选 Hyper 键选项且辅助功能权限已授予
- **THEN** 系统 SHALL 开始拦截 Right Command 事件

#### Scenario: 按下 Right Command
- **WHEN** 启用 Hyper 键且用户按下 Right Command
- **THEN** 系统 SHALL 抑制原始事件，发送 Ctrl+Shift+Option+Cmd 四个修饰键按下事件

#### Scenario: 长按 Right Command（重复事件）
- **WHEN** 启用 Hyper 键且用户长按 Right Command（系统发送重复 keyDown）
- **THEN** 系统 SHALL 忽略重复事件，不重复发送修饰键按下事件

#### Scenario: 松开 Right Command
- **WHEN** 启用 Hyper 键且用户松开 Right Command
- **THEN** 系统 SHALL 抑制原始事件，发送 Ctrl+Shift+Option+Cmd 四个修饰键松开事件

#### Scenario: 禁用 Hyper 键
- **WHEN** 用户取消勾选 Hyper 键选项
- **THEN** 系统 SHALL 停止拦截 Right Command，恢复原行为

### Requirement: 引号互换（CGEventTap）
系统 SHALL 通过 CGEventTap 交换单引号（'）和双引号（"）的输出。按下 Quote 发送双引号，按下 Shift+Quote 发送单引号。

#### Scenario: 启用引号互换
- **WHEN** 用户勾选引号互换选项且辅助功能权限已授予
- **THEN** 系统 SHALL 开始拦截 Quote 键事件

#### Scenario: 按下 Quote 键（无 Shift）
- **WHEN** 启用引号互换且用户按下 Quote 键
- **THEN** 系统 SHALL 添加 Shift 修饰，发送 Quote 事件（产生双引号）

#### Scenario: 按下 Shift+Quote
- **WHEN** 启用引号互换且用户按下 Shift+Quote
- **THEN** 系统 SHALL 移除 Shift 修饰，发送 Quote 事件（产生单引号）

#### Scenario: 禁用引号互换
- **WHEN** 用户取消勾选引号互换选项
- **THEN** 系统 SHALL 停止拦截 Quote 键，恢复原行为

### Requirement: 映射状态持久化
系统 SHALL 将三个映射的启用状态持久化到 UserDefaults，键名分别为 `keyRemapCapsControlSwap`、`keyRemapHyperKey`、`keyRemapQuoteSwap`。

#### Scenario: 应用重启后恢复映射
- **WHEN** 应用重启
- **THEN** 系统 SHALL 从 UserDefaults 读取上次状态，自动启用用户选中的映射

### Requirement: 修饰键状态重置
系统 SHALL 在 CGEventTap 服务启动时发送一次所有修饰键松开事件，防止因上次异常退出导致修饰键"卡住"。

#### Scenario: 服务启动时重置修饰键
- **WHEN** CGEventTap 启动
- **THEN** 系统 SHALL 发送 Ctrl、Shift、Option、Cmd 的松开事件
