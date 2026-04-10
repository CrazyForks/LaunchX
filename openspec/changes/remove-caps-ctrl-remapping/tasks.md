## 1. 移除 KeyRemapService 中的 Caps/Ctrl 逻辑

- [x] 1.1 移除 `kHIDCapsLock` 和 `kHIDLeftControl` 两个 HID 常量（KeyRemapService.swift 第 8-9 行）
- [x] 1.2 移除 `capsControlSwapEnabled` 属性及其 `didSet`（第 19-25 行）
- [x] 1.3 移除 `applyCapsControlSwap()` 方法（第 63-93 行）
- [x] 1.4 移除 `enumerateKeyboardMappingKeys()` 方法（第 96-111 行）
- [x] 1.5 移除 `detectCapsControlSwap()` 方法（第 114-125 行）
- [x] 1.6 修改 `applySettings()` 方法签名，移除 `capsSwap` 参数，更新方法体移除 caps 相关逻辑

## 2. 移除 UI 中的 Caps/Ctrl 开关

- [x] 2.1 移除 `@AppStorage("keyRemapCapsControlSwap")` 属性（SettingsView.swift 第 697 行）
- [x] 2.2 移除 `@State private var systemHasCapsSwap` 属性（第 702 行）
- [x] 2.3 移除 Caps ↔ Control 的 Toggle UI 代码（第 713-717 行）
- [x] 2.4 移除系统冲突警告 UI 代码（第 735-755 行）
- [x] 2.5 移除 onAppear 中的 caps/ctrl 自动检测和启用逻辑（第 774-786 行中相关部分）

## 3. 更新 App 生命周期调用

- [x] 3.1 修改 `applyKeyRemapSettings()` 方法，移除 `capsSwap` 变量的读取和传递（LanuchXApp.swift 第 102-111 行）

## 4. 验证

- [x] 4.1 确认 Hyper Key 功能正常工作
- [x] 4.2 确认引号互换功能正常工作
- [x] 4.3 确认 Settings UI 仅显示两项按键映射选项
- [x] 4.4 编译通过，无编译错误或警告
