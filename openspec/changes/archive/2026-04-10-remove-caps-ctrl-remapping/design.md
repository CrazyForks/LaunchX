## Context

LaunchX 的按键映射功能目前包含三项：Caps ↔ Control 互换、Hyper Key（右⌘）、引号互换。其中 Caps ↔ Control 互换通过修改系统级 HID 映射（`hidutil` + `defaults`）实现，会在全局影响所有键盘设备。

当前实现涉及三个文件：
- `KeyRemapService.swift`：核心服务，包含 HID 常量、swap 逻辑、系统检测
- `SettingsView.swift`：`KeyRemapSettingsView` 中的 UI 开关和系统冲突警告
- `LanuchXApp.swift`：应用启动时应用设置的调用

## Goals / Non-Goals

**Goals:**
- 完全移除 Caps ↔ Control 互换功能的所有代码和 UI
- 确保 Hyper Key 和引号互换功能不受影响
- 保持 `applySettings()` 方法签名简洁

**Non-Goals:**
- 不主动清理用户系统中已存在的 HID 映射（用户需自行在系统设置中恢复）
- 不修改 Hyper Key 或引号互换的任何逻辑
- 不添加引导用户去系统设置的新 UI

## Decisions

### 1. 直接删除而非禁用

**决定**：完全移除代码，而非保留但隐藏功能。

**理由**：功能本身在多键盘场景下有设计缺陷，保留代码会增加维护负担且无实际价值。系统设置中已有完善的修饰键映射功能。

**替代方案**：保留代码但默认禁用 → 不采纳，因为多键盘问题未解决，保留只会增加困惑。

### 2. 不主动清理系统 HID 映射

**决定**：不在移除时主动调用 `hidutil` 清除已有映射。

**理由**：
- 用户可能通过系统设置手动配置了类似的映射，清除会破坏用户意图
- 应用更新不应静默修改系统级设置
- 在 CHANGELOG 中提醒用户手动检查即可

### 3. 简化 applySettings 方法签名

**决定**：移除 `capsSwap` 参数，方法签名变为 `applySettings(hyper:quote:)`。

**理由**：参数不再需要，保持 API 简洁。

### 4. 移除 `enumerateKeyboardMappingKeys()` 和 `detectCapsControlSwap()`

**决定**：这两个方法仅服务于 caps/ctrl swap 功能，一并移除。

**理由**：无其他代码依赖这些方法。

## Risks / Trade-offs

- **[风险] 用户升级后系统中可能残留 HID 映射** → 缓解：在 CHANGELOG 和 release notes 中说明，建议用户检查系统设置 → 键盘 → 修饰键
- **[风险] 习惯了该功能的用户升级后找不到开关** → 缓解：这是一个破坏性变更，但功能本身有缺陷，长期来看是正确决定
