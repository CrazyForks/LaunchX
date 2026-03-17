## ADDED Requirements

### Requirement: Reminders Extension Type
系统 MUST 在 AdvancedExtensionType 枚举中添加提醒事项扩展类型。

#### Scenario: Reminders extension type is defined
- **WHEN** AdvancedExtensionType enum is accessed
- **THEN** it MUST include a `reminders` case with display name "提醒事项"

#### Scenario: Reminders extension has appropriate icon
- **WHEN** reminders extension type is displayed
- **THEN** it MUST use SF Symbol "checklist" as the icon

#### Scenario: Reminders extension has distinct color
- **WHEN** reminders extension type is displayed
- **THEN** it MUST use purple color to distinguish from other extensions

### Requirement: Reminders Settings View
系统 MUST 提供 RemindersSettingsView 用于管理提醒事项功能。

#### Scenario: Settings view displays header with toggle
- **WHEN** RemindersSettingsView is displayed
- **THEN** it MUST show header with reminders icon, title "提醒事项", and a toggle switch

#### Scenario: Settings view follows header style standards
- **WHEN** RemindersSettingsView is displayed
- **THEN** the header MUST follow SettingsHeaderStyle standards (icon size, title font, padding, spacing)

#### Scenario: Settings view is accessible from advanced extensions
- **WHEN** user selects reminders in AdvancedExtensionsView
- **THEN** RemindersSettingsView MUST be displayed in the detail pane

### Requirement: Reminders Enable/Disable Toggle
用户 MUST 能够通过开关控制提醒事项功能的启用状态。

#### Scenario: Toggle enables reminders feature
- **WHEN** user turns on the reminders toggle
- **THEN** the system MUST save the enabled state and trigger authorization request if not already authorized

#### Scenario: Toggle disables reminders feature
- **WHEN** user turns off the reminders toggle
- **THEN** the system MUST save the disabled state and stop loading reminders data

#### Scenario: Toggle state persists across app restarts
- **WHEN** user changes the toggle state and restarts the app
- **THEN** the toggle MUST reflect the previously saved state

### Requirement: Authorization Status Display
系统 MUST 显示提醒事项的授权状态。

#### Scenario: Display authorized status
- **WHEN** reminders are enabled and system authorization is granted
- **THEN** the view MUST display "已授权" status with a checkmark icon

#### Scenario: Display unauthorized status
- **WHEN** reminders are enabled but system authorization is not granted
- **THEN** the view MUST display "未授权" status with a warning icon

#### Scenario: Display disabled status
- **WHEN** reminders toggle is off
- **THEN** authorization status MUST not be displayed or show as inactive

### Requirement: Authorization Request Button
系统 MUST 提供授权按钮供用户主动触发授权请求。

#### Scenario: Show authorization button when unauthorized
- **WHEN** reminders are enabled but not authorized
- **THEN** the view MUST display an "授权" button

#### Scenario: Hide authorization button when authorized
- **WHEN** reminders are enabled and already authorized
- **THEN** the authorization button MUST not be displayed

#### Scenario: Authorization button triggers system dialog
- **WHEN** user clicks the authorization button
- **THEN** the system MUST call RemindersService.requestAccess to show system authorization dialog

#### Scenario: Authorization status updates after granting
- **WHEN** user grants authorization through system dialog
- **THEN** the view MUST update to show "已授权" status and hide the authorization button

### Requirement: Feature Description
系统 MUST 提供清晰的功能说明文字。

#### Scenario: Display feature description
- **WHEN** RemindersSettingsView is displayed
- **THEN** it MUST show explanatory text describing what the reminders feature does

#### Scenario: Description explains data source
- **WHEN** feature description is displayed
- **THEN** it MUST mention that reminders are fetched from system Reminders app

#### Scenario: Description explains display criteria
- **WHEN** feature description is displayed
- **THEN** it MUST explain that only today's and overdue reminders are shown

### Requirement: Settings Persistence
提醒事项设置 MUST 持久化存储在 UserDefaults 中。

#### Scenario: Settings are saved on toggle change
- **WHEN** user changes the reminders toggle state
- **THEN** the new state MUST be immediately saved to UserDefaults

#### Scenario: Settings are loaded on view appear
- **WHEN** RemindersSettingsView appears
- **THEN** it MUST load the saved settings from UserDefaults

#### Scenario: Default state for new users
- **WHEN** a new user opens RemindersSettingsView for the first time
- **THEN** the toggle MUST default to off (disabled)

### Requirement: Backward Compatibility
系统 MUST 为已授权用户提供向后兼容支持。

#### Scenario: Existing authorized users have feature enabled
- **WHEN** app upgrades and user has previously granted reminders authorization
- **THEN** RemindersSettings.isEnabled MUST default to true for that user

#### Scenario: New users start with feature disabled
- **WHEN** a new user installs the app
- **THEN** RemindersSettings.isEnabled MUST default to false

#### Scenario: Migration check runs on app launch
- **WHEN** app launches after upgrade
- **THEN** the system MUST check if user has existing authorization and set isEnabled accordingly
