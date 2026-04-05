## ADDED Requirements

### Requirement: 在通用设置中显示键盘映射设置
系统 SHALL 在通用设置 Tab 中，液态玻璃设置的下方，显示键盘映射设置区域。该区域 SHALL 包含标题 "键盘映射:" 和三个 Checkbox 控件。

#### Scenario: 显示键盘映射设置
- **WHEN** 用户打开通用设置 Tab
- **THEN** 系统 SHALL 在液态玻璃设置下方显示标题 "键盘映射:" 及三个 Checkbox: "Caps ↔ Control 互换"、"Hyper 键 (右Command)"、"引号互换"

### Requirement: Caps ↔ Control 互换 Checkbox（无需额外权限）
系统 SHALL 提供 "Caps ↔ Control 互换" Checkbox，启用时通过 IOKit 设置 UserKeyMapping 互换 Caps Lock 和 Left Control。此功能无需辅助功能权限。

#### Scenario: 勾选 Caps ↔ Control 互换
- **WHEN** 用户勾选 "Caps ↔ Control 互换" Checkbox
- **THEN** 系统 SHALL 立即将启用状态保存到 UserDefaults，并通过 IOKit 设置 UserKeyMapping 启用映射

#### Scenario: 取消勾选 Caps ↔ Control 互换
- **WHEN** 用户取消勾选 "Caps ↔ Control 互换" Checkbox
- **THEN** 系统 SHALL 立即将禁用状态保存到 UserDefaults，并通过 IOKit 清除 UserKeyMapping 恢复默认

### Requirement: Hyper 键和引号互换需要辅助功能权限
系统 SHALL 检测辅助功能权限状态。未授权时，"Hyper 键" 和 "引号互换" Checkbox SHALL 显示为禁用状态，并显示权限提示。

#### Scenario: 辅助功能权限已授予
- **WHEN** 辅助功能权限已授予
- **THEN** 系统 SHALL 启用 "Hyper 键" 和 "引号互换" Checkbox，用户可以正常使用

#### Scenario: 辅助功能权限未授予
- **WHEN** 辅助功能权限未授予
- **THEN** 系统 SHALL 禁用 "Hyper 键" 和 "引号互换" Checkbox，并显示提示 "Hyper 键和引号互换需要辅助功能权限" 及"打开系统设置"按钮

### Requirement: Hyper 键 Checkbox
系统 SHALL 提供 "Hyper 键 (右Command)" Checkbox，启用时将 Right Command 映射为 Ctrl+Cmd+Shift+Option。此功能需要辅助功能权限。

#### Scenario: 勾选 Hyper 键
- **WHEN** 用户勾选 "Hyper 键 (右Command)" Checkbox 且辅助功能权限已授予
- **THEN** 系统 SHALL 立即将启用状态保存到 UserDefaults，并通过 CGEventTap 启用映射

#### Scenario: 取消勾选 Hyper 键
- **WHEN** 用户取消勾选 "Hyper 键 (右Command)" Checkbox
- **THEN** 系统 SHALL 立即将禁用状态保存到 UserDefaults，并停止 CGEventTap 拦截 Right Command

### Requirement: 引号互换 Checkbox
系统 SHALL 提供 "引号互换" Checkbox，启用时交换单引号和双引号的输出。此功能需要辅助功能权限。

#### Scenario: 勾选引号互换
- **WHEN** 用户勾选 "引号互换" Checkbox 且辅助功能权限已授予
- **THEN** 系统 SHALL 立即将启用状态保存到 UserDefaults，并通过 CGEventTap 启用映射

#### Scenario: 取消勾选引号互换
- **WHEN** 用户取消勾选 "引号互换" Checkbox
- **THEN** 系统 SHALL 立即将禁用状态保存到 UserDefaults，并停止 CGEventTap 拦截 Quote 键

### Requirement: 打开系统设置按钮
系统 SHALL 在辅助功能权限未授予时显示"打开系统设置"按钮，点击后打开系统设置的隐私与安全性 → 辅助功能页面。

#### Scenario: 点击打开系统设置
- **WHEN** 用户点击"打开系统设置"按钮
- **THEN** 系统 SHALL 打开系统设置的辅助功能页面，URL: `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`
