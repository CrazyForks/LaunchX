## Context

LaunchX 是一款 macOS 效率启动器（类似 Raycast/HapiGo），使用 Swift + SwiftUI/AppKit 构建。用户希望完全脱离 Karabiner-Elements，在应用内自行实现按键重映射。

macOS 提供两种按键重映射机制：
1. **IOKit 原生映射** — 修改键盘硬件映射表，内核级，零延迟
2. **CGEventTap** — 用户空间事件拦截与重写，回调机制，微秒级延迟

## Goals / Non-Goals

**Goals:**
- 完全脱离 Karabiner-Elements，自行实现三种常用按键映射
- 保持高性能低延迟（Caps↔Control 零延迟，其他微秒级）
- 正确处理按键状态追踪，避免长按时重复触发
- 在通用设置界面提供简洁的开关 UI

**Non-Goals:**
- 不实现通用的按键映射编辑器（只支持这三种预设规则）
- 不使用 DriverKit 虚拟 HID（开发成本过高，需要特殊签名权限）
- 不处理 Secure Input 期间的事件（密码输入框，CGEventTap 限制）

## Decisions

### D1: Caps↔Control 使用 IOKit 原生 API（UserKeyMapping）

**选择**: 通过 IOKit 的 `IORegistryEntrySetCFProperty` 设置 `UserKeyMapping` 属性

**理由**:
- macOS 系统偏好设置「键盘 → 修饰键」就是用这个 API
- 内核级映射，零延迟，零 CPU 开销
- 不需要事件监听，一次设置永久生效（系统级，重启后仍有效）
- 无需辅助功能权限

**实现**:
```swift
// 伪代码 - 遍历所有键盘设备
let matching = IOServiceMatching(kIOHIDDeviceKey)
var iter: io_iterator_t = 0
IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iter)

while let service = IOIteratorNext(iter) {
    // 设置 UserKeyMapping：Caps Lock(0x70000039) ↔ Left Control(0x700000E0)
    let mapping: [[String: Int]] = [
        ["HIDKeyboardModifierMappingSrc": 0x70000039, "HIDKeyboardModifierMappingDst": 0x700000E0],
        ["HIDKeyboardModifierMappingSrc": 0x700000E0, "HIDKeyboardModifierMappingDst": 0x70000039]
    ]
    IORegistryEntrySetCFProperty(service, "UserKeyMapping" as CFString, mapping as CFArray)
    IOObjectRelease(service)
}
```

**键码** (HID Usage ID):
- Caps Lock: `0x70000039`
- Left Control: `0x700000E0`

**禁用映射**: 设置空数组 `[]` 恢复默认

**替代方案**: CGEventTap 拦截 — 延迟更高，需要辅助功能权限，不如 IOKit 优雅

### D2: Hyper 键使用 CGEventTap + 状态追踪

**选择**: CGEventTap 拦截 Right Command，用状态变量追踪按下/松开

**实现逻辑**:
```
Right Command KeyDown (首次):
  → 抑制原事件
  → 发送 Ctrl+Shift+Option+Cmd 四个修饰键按下事件
  → 设置 rightCommandPressed = true

Right Command KeyDown (重复，长按期间):
  → 抑制原事件
  → 忽略（不重复发送修饰键）

Right Command KeyUp:
  → 抑制原事件
  → 发送 Ctrl+Shift+Option+Cmd 四个修饰键松开事件
  → 设置 rightCommandPressed = false
```

**状态变量**:
- `rightCommandPressed: Bool` — 防止长按时重复触发

**性能**: 回调内只做简单的键码判断和 Bool 检查，耗时 < 1 微秒

### D3: 引号互换使用 CGEventTap 翻转 Shift

**选择**: 拦截 Quote 键，翻转 Shift 修饰键状态

**实现逻辑**:
```
Quote + Shift 按下:
  → 移除 Shift 修饰
  → 发送 Quote（产生单引号）

Quote 按下（无 Shift）:
  → 添加 Shift 修饰
  → 发送 Quote（产生双引号）
```

### D4: CGEventTap 配置

**选择**: `CGEventTapCreate` with `cghidEventTap` location, `headInsertEventTap` option

**参数**:
- `tap`: `cghidEventTap` — 在 HID 级别拦截
- `place`: `headInsertEventTap` — 优先处理
- `options`: `defaultTap` — 允许修改事件
- `eventsOfInterest`: `CGEventMask(1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)`

**线程**: 回调在主线程 RunLoop 执行，确保 UI 线程安全

### D5: 辅助功能权限检测

**选择**: 使用 `AXIsProcessTrusted()` 检测权限

**流程**:
1. 应用启动时检测辅助功能权限
2. 未授权时在 UI 显示提示，引导用户去系统设置授权
3. 授权后才能启用 CGEventTap 相关的映射

## Risks / Trade-offs

- **[Secure Input 失效]** → 密码输入框期间 CGEventTap 不工作，这是 macOS 安全限制，无法绕过。对日常使用影响极小。
- **[权限被撤销]** → 定期检测 `AXIsProcessTrusted()`，权限丢失时禁用映射并提示
- **[长按状态不同步]** → 如果应用崩溃，修饰键可能"卡住"。解决方案：应用启动时发送一次所有修饰键松开事件
- **[与其他快捷键软件冲突]** → headInsert 确保优先处理，但其他软件也可能 headInsert。无法完全避免。
- **[性能顾虑]** → 回调内只做纯内存操作（键码判断 + 状态追踪），实测 CPU 可忽略。长按不会导致 CPU 飙升。
