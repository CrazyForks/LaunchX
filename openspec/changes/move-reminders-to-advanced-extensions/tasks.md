## 1. 创建 RemindersSettings 配置结构

- [x] 1.1 创建 RemindersSettings.swift 文件，定义 RemindersSettings 结构体
- [x] 1.2 添加 isEnabled 属性（Bool 类型，默认 false）
- [x] 1.3 实现 load() 静态方法从 UserDefaults 加载设置
- [x] 1.4 实现 save() 方法保存设置到 UserDefaults
- [x] 1.5 定义 UserDefaults key 常量（如 "remindersEnabled"）

## 2. 更新 AdvancedExtensionType 枚举

- [x] 2.1 在 AdvancedExtensionsView.swift 的 AdvancedExtensionType 枚举中添加 `case reminders = "提醒事项"`
- [x] 2.2 在 sfSymbolName 计算属性中为 reminders case 返回 "checklist"
- [x] 2.3 在 iconColor 计算属性中为 reminders case 返回 .purple

## 3. 创建 RemindersSettingsView

- [x] 3.1 创建 RemindersSettingsView.swift 文件
- [x] 3.2 实现顶部 header（图标 + 标题 + Toggle 开关），遵循 SettingsHeaderStyle 标准
- [x] 3.3 添加 @State 变量管理 settings 和 authorizationStatus
- [x] 3.4 实现授权状态显示区域（已授权/未授权）
- [x] 3.5 实现授权按钮（仅在未授权时显示）
- [x] 3.6 添加功能说明文字（解释提醒事项功能）
- [x] 3.7 实现 onAppear 加载设置和检查授权状态
- [x] 3.8 实现 Toggle onChange 保存设置并触发授权（如需要）

## 4. 集成 RemindersSettingsView 到 AdvancedExtensionsView

- [x] 4.1 在 AdvancedExtensionsView 的 extensionSettings 计算属性中添加 reminders case
- [x] 4.2 在 reminders case 中返回 RemindersSettingsView()

## 5. 移除启动时的自动授权请求

- [x] 5.1 在 SearchPanelViewController.swift 的 viewDidLoad 中移除 RemindersService.shared.requestAccess 调用
- [x] 5.2 修改提醒事项加载逻辑，仅在 RemindersSettings.isEnabled == true 时加载
- [x] 5.3 在 loadReminders() 方法前添加 isEnabled 检查

## 6. 实现向后兼容逻辑

- [x] 6.1 在 AppDelegate 或 LanuchXApp.swift 的启动方法中添加迁移逻辑
- [x] 6.2 检查 RemindersService.checkAuthorization() 是否返回 true
- [x] 6.3 如果已授权且 RemindersSettings 未初始化，设置 isEnabled 为 true
- [x] 6.4 保存迁移后的设置

## 7. 测试和验证

- [x] 7.1 测试新用户场景：默认关闭，需手动开启
- [x] 7.2 测试已授权用户升级场景：自动启用功能
- [x] 7.3 测试开关切换：启用时触发授权，禁用时停止加载
- [x] 7.4 测试授权按钮：点击后显示系统授权对话框
- [x] 7.5 测试授权状态显示：正确显示已授权/未授权状态
- [x] 7.6 测试设置持久化：重启应用后状态保持
- [x] 7.7 验证提醒事项功能：启用后正常显示提醒事项
