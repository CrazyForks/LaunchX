## Context

当前提醒事项功能在 `SearchPanelViewController` 的 `viewDidLoad` 中自动调用 `RemindersService.shared.requestAccess`，这会在应用启动后立即弹出系统授权对话框。这种设计存在以下问题：

1. 用户体验不佳：在用户还未了解功能价值时就要求授权
2. 缺少控制入口：如果用户拒绝授权，后续没有地方可以重新开启
3. 不符合现有架构：其他高级功能（如书签搜索、2FA）都在高级拓展设置中管理

现有架构中，高级拓展通过 `AdvancedExtensionsView` 统一管理，每个扩展都有独立的设置视图，包含功能开关和相关配置。

## Goals / Non-Goals

**Goals:**
- 将提醒事项功能集成到高级拓展设置中，与其他扩展保持一致的交互模式
- 提供清晰的开关控制，让用户可以随时启用或禁用提醒事项功能
- 移除应用启动时的自动授权请求，改为用户主动触发
- 保持现有提醒事项功能逻辑不变，仅改变授权触发时机

**Non-Goals:**
- 不修改 `RemindersService` 的核心功能逻辑
- 不改变提醒事项的显示方式和交互逻辑
- 不添加新的提醒事项功能特性

## Decisions

### 1. 使用 UserDefaults 存储提醒事项开关状态

**决策：** 创建 `RemindersSettings` 结构体，使用 UserDefaults 持久化存储用户的启用/禁用偏好。

**理由：**
- 与现有的 `BookmarkSettings`、`ClipboardSettings` 等保持一致的架构模式
- UserDefaults 足够轻量，适合存储简单的布尔值配置
- 便于在应用启动时快速读取配置，决定是否加载提醒事项

**替代方案：**
- 使用 `@AppStorage`：更现代但与现有代码风格不一致
- 直接使用 UserDefaults 而不封装：缺少类型安全和代码组织

### 2. 在 AdvancedExtensionType 中添加 reminders 类型

**决策：** 在 `AdvancedExtensionType` 枚举中添加 `case reminders = "提醒事项"`，使用 SF Symbol `"checklist"` 作为图标，颜色使用 `.purple`。

**理由：**
- 符合现有的扩展注册模式
- 提醒事项的图标和颜色需要与其他扩展区分
- `checklist` 图标最能代表提醒事项的功能特征

**替代方案：**
- 使用 `"bell.fill"` 图标：更像通知而非提醒事项
- 使用 `.yellow` 颜色：与 snippet 的 `.orange` 过于接近

### 3. 创建 RemindersSettingsView 遵循现有设计模式

**决策：** 创建新的 `RemindersSettingsView`，包含以下元素：
- 顶部：图标 + 标题 + Toggle 开关（与 BookmarkSearchSettingsView 一致）
- 授权状态显示：显示当前授权状态（未授权/已授权）
- 授权按钮：仅在未授权时显示，点击触发系统授权对话框
- 说明文字：解释提醒事项功能的作用

**理由：**
- 与 `BookmarkSearchSettingsView` 和 `TwoFactorAuthSettingsView` 保持一致的 UI 结构
- 用户熟悉的交互模式，降低学习成本
- 清晰的授权状态反馈

**替代方案：**
- 自动触发授权：违背了用户主动控制的设计目标
- 复杂的多步骤引导：对于简单的授权流程过于繁琐

### 4. 条件加载提醒事项数据

**决策：** 在 `SearchPanelViewController` 中，仅当 `RemindersSettings.isEnabled == true` 且已授权时才加载提醒事项数据。移除 `viewDidLoad` 中的自动 `requestAccess` 调用。

**理由：**
- 尊重用户的选择，不在用户禁用功能时消耗资源
- 避免不必要的系统权限检查和数据加载
- 保持与其他扩展功能的一致性（如书签搜索也是条件加载）

**替代方案：**
- 始终加载但不显示：浪费资源且不符合用户预期
- 延迟加载：增加复杂度，收益不明显

### 5. 保持向后兼容

**决策：** 对于已经授权的用户，默认将 `RemindersSettings.isEnabled` 设置为 `true`，确保升级后功能继续可用。

**理由：**
- 避免破坏现有用户的使用体验
- 已授权用户显然希望使用该功能
- 新用户默认为 `false`，需要主动开启

**实现方式：**
- 在应用启动时检查：如果 `RemindersService.checkAuthorization() == true` 且 `RemindersSettings` 未初始化，则设置为 `true`

## Risks / Trade-offs

**[风险] 功能发现率可能降低** → 缓解措施：
- 在设置界面中突出显示高级拓展入口
- 考虑在首次启动引导中提及高级拓展功能
- 保持清晰的功能命名和图标设计

**[风险] 已授权用户升级后可能困惑** → 缓解措施：
- 实现向后兼容逻辑，已授权用户自动启用
- 在更新日志中说明变更

**[权衡] 增加一次点击成本** → 接受：
- 用户需要进入设置才能启用功能
- 但换来了更好的控制权和清晰的功能管理
- 符合 macOS 应用的常见模式

**[权衡] 需要创建新的设置视图** → 接受：
- 增加少量代码，但提升了架构一致性
- 便于未来扩展提醒事项相关配置（如过滤规则、显示数量等）
