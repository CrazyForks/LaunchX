## 1. KeyRemapService 核心实现

- [ ] 1.1 创建 `Services/Features/KeyRemapService.swift`，实现单例模式
- [ ] 1.2 实现辅助功能权限检测：`AXIsProcessTrusted()`，提供 `hasAccessibilityPermission` 属性
- [ ] 1.3 实现 IOKit 键盘设备遍历：通过 `IOServiceMatching(kIOHIDDeviceKey)` 获取所有键盘设备
- [ ] 1.4 实现 Caps↔Control 互换（IOKit）：通过 `IORegistryEntrySetCFProperty` 设置 `UserKeyMapping`，双向映射 Caps Lock(0x70000039) ↔ Left Control(0x700000E0)
- [ ] 1.5 实现 Caps↔Control 禁用：设置空 UserKeyMapping 数组恢复默认
- [ ] 1.6 实现 CGEventTap 创建与启停：监听 keyDown、keyUp、flagsChanged 事件，在主线程 RunLoop 运行
- [ ] 1.7 实现修饰键状态追踪：`rightCommandPressed: Bool` 防止 Hyper 键长按重复触发
- [ ] 1.8 实现 Hyper 键（CGEventTap）：拦截 `kVK_RightCommand`，按下时发送 Ctrl+Shift+Option+Cmd，松开时发送对应松开事件
- [ ] 1.9 实现引号互换（CGEventTap）：拦截 `kVK_Quote`，翻转 Shift 修饰键状态后重发
- [ ] 1.10 实现修饰键状态重置：CGEventTap 启动时发送所有修饰键松开事件，防止卡住

## 2. 设置 UI 实现

- [ ] 2.1 在 `Views/SettingsView.swift` 的通用设置 Tab 中，液态玻璃设置下方新增键盘映射设置区域
- [ ] 2.2 实现辅助功能权限未授予时的提示 UI（显示提示 + "打开系统设置"按钮），仅影响 Hyper 键和引号互换
- [ ] 2.3 实现三个 Checkbox UI："Caps ↔ Control 互换"、"Hyper 键 (右Command)"、"引号互换"
- [ ] 2.4 绑定 Checkbox 状态到 UserDefaults（`keyRemapCapsControlSwap`、`keyRemapHyperKey`、`keyRemapQuoteSwap`）
- [ ] 2.5 实现 Checkbox 变更回调：Caps↔Control 调用 IOKit 方法，Hyper/引号 调用 CGEventTap 方法
- [ ] 2.6 实现"打开系统设置"按钮：打开 `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`

## 3. 集成与生命周期

- [ ] 3.1 应用启动时从 UserDefaults 读取映射状态，恢复用户上次的设置
- [ ] 3.2 Caps↔Control 互换在应用启动时自动应用（无需辅助功能权限）
- [ ] 3.3 Hyper 键和引号互换在辅助功能权限授予后自动启动
- [ ] 3.4 应用退出时清理 CGEventTap（Caps↔Control 映射保持，因为是系统级设置）
- [ ] 3.5 测试三种映射的启用/禁用，确认按键行为正确
- [ ] 3.6 测试长按 Right Command，确认不会重复发送修饰键事件
- [ ] 3.7 测试系统重启后 Caps↔Control 映射是否需要重新应用
