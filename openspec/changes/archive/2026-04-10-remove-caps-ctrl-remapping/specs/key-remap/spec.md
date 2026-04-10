## REMOVED Requirements

### Requirement: Caps ↔ Control key swap
**Reason**: 多键盘场景下存在兼容性问题（如 HHKB 等键盘 Ctrl 本身就在 Caps 位置），且系统设置已提供完善的修饰键映射功能。
**Migration**: 用户可通过 macOS 系统设置 → 键盘 → 修饰键手动配置 Caps Lock 和 Control 的映射。

#### Scenario: User previously had caps-ctrl swap enabled
- **WHEN** user upgrades to a version without caps-ctrl swap
- **THEN** the app SHALL NOT display any caps-ctrl swap UI toggle
- **THEN** the app SHALL NOT modify system HID mappings on launch

## ADDED Requirements

### Requirement: Key remap settings only show Hyper and Quote options
应用 SHALL 仅显示 Hyper Key 和引号互换两个按键映射选项，不再包含 Caps ↔ Control 互换。

#### Scenario: User opens keyboard remap settings
- **WHEN** user navigates to keyboard remap settings section
- **THEN** system SHALL display exactly two toggle options: Hyper Key and Quote Swap
- **THEN** system SHALL NOT display any caps-ctrl swap toggle

#### Scenario: App applies saved key remap settings on launch
- **WHEN** app launches and accessibility permission is granted
- **THEN** system SHALL read only `keyRemapHyperKey` and `keyRemapQuoteSwap` from UserDefaults
- **THEN** system SHALL apply only Hyper Key and Quote Swap remappings

### Requirement: KeyRemapService only handles Hyper and Quote remapping
KeyRemapService SHALL NOT contain any caps/ctrl swap logic, HID constants, or system detection methods.

#### Scenario: KeyRemapService applySettings called
- **WHEN** `applySettings(hyper:quote:)` is called
- **THEN** service SHALL apply only Hyper Key and Quote Swap remappings
- **THEN** service SHALL NOT modify any HID modifier mappings for Caps Lock or Control keys
