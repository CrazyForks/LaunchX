## Why

Caps ↔ Control 互换功能在多键盘场景下存在问题。例如 HHKB 等键盘的 Ctrl 键本身就位于 Caps Lock 位置，该功能会导致这些键盘的按键行为异常。此功能本质上是对系统级 HID 映射的修改，应该由用户在 macOS 系统设置中手动配置，而非由应用层面处理。

## What Changes

- **BREAKING** 移除 Caps ↔ Control 互换功能的所有相关代码
- 移除 `KeyRemapService` 中 caps/ctrl swap 相关的属性、方法和检测逻辑
- 移除 `KeyRemapSettingsView` 中的 Caps ↔ Control 开关及相关警告 UI
- 移除 `LanuchXApp` 中对该功能的调用
- 清理相关的 UserDefaults key (`keyRemapCapsControlSwap`)
- 保留 Hyper Key 和引号互换功能不受影响

## Capabilities

### New Capabilities

（无新增能力）

### Modified Capabilities

- `key-remap`: 移除 caps-ctrl swap 功能，仅保留 Hyper Key 和引号互换

## Impact

- **KeyRemapService.swift**: 移除 caps/ctrl swap 相关的 HID 常量、状态属性、`applyCapsControlSwap()`、`detectCapsControlSwap()`、`enumerateKeyboardMappingKeys()` 等方法；`applySettings()` 方法签名变更（移除 `capsSwap` 参数）
- **SettingsView.swift**: `KeyRemapSettingsView` 移除 caps/ctrl toggle、系统冲突警告、`systemHasCapsSwap` 状态、onAppear 中的自动检测逻辑
- **LanuchXApp.swift**: `applyKeyRemapSettings()` 移除 capsSwap 参数的读取和传递
- **UserDefaults**: `keyRemapCapsControlSwap` key 不再使用（无需主动清理，不影响用户）

### Rollback Plan

通过 git revert 即可完整回滚。所有被移除的代码均在 git 历史中，无外部依赖或数据迁移风险。如果用户之前已通过该功能设置了系统级 HID 映射，建议用户前往系统设置 → 键盘 → 修饰键中手动恢复。
