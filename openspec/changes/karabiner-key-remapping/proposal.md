## Why

用户希望完全脱离 Karabiner-Elements，在 LaunchX 中自行实现三个常用按键重映射（Caps↔Control 互换、Hyper 键、引号交换），避免依赖外部软件，同时保持高性能低延迟。

## What Changes

- 在通用设置界面的液态玻璃设置下方，新增键盘映射设置的 Checkbox 控件
- 新增 `KeyRemapService` 服务，使用 macOS 原生 API 实现按键重映射：
  1. **Caps Lock ↔ Control 互换** — 使用 IOKit 原生 API 直接修改键盘硬件映射（内核级，零延迟）
  2. **Hyper 键**（Right Command → Ctrl+Cmd+Shift+Option）— 使用 CGEventTap 拦截并重映射
  3. **单引号 ↔ 双引号互换** — 使用 CGEventTap 拦截并翻转 Shift 状态
- 设置状态持久化到 UserDefaults，应用启动时自动启用已选中的映射
- 需要辅助功能权限（Accessibility）才能使用 CGEventTap

## Capabilities

### New Capabilities
- `key-remap-service`: 按键重映射核心服务，使用 IOKit + CGEventTap 实现三种映射规则
- `keyboard-settings-ui`: 通用设置页面中的键盘映射 Checkbox UI 及权限检测

### Modified Capabilities
（无已有规格需要修改）

## Impact

- **新增文件**: `Services/Features/KeyRemapService.swift`（按键重映射服务）
- **修改文件**: `Views/SettingsView.swift`（通用设置 Tab 中新增 UI 区域）
- **权限需求**: 需要辅助功能权限（Accessibility）用于 CGEventTap 监听键盘事件
- **性能**:
  - Caps↔Control 使用 IOKit 内核级映射，零延迟零 CPU 开销
  - Hyper 键和引号互换使用 CGEventTap，回调机制（非轮询），回调内只做微秒级简单操作，CPU 开销可忽略
  - 长按按键不会导致 CPU 飙升（正确实现状态追踪，忽略重复事件）
- **回滚方案**: 删除新增代码、禁用映射即可恢复原状
- **限制**: CGEventTap 在 Secure Input（密码输入框）期间会暂时失效
