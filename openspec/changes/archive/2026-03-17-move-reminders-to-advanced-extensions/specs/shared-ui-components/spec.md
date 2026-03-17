## ADDED Requirements

### Requirement: Reminders Extension Type in AdvancedExtensionType
AdvancedExtensionType 枚举 MUST 包含提醒事项扩展类型。

#### Scenario: Reminders case is added to enum
- **WHEN** AdvancedExtensionType enum is evaluated
- **THEN** it MUST include `case reminders = "提醒事项"`

#### Scenario: Reminders icon is defined
- **WHEN** reminders extension type sfSymbolName is accessed
- **THEN** it MUST return "checklist"

#### Scenario: Reminders color is defined
- **WHEN** reminders extension type iconColor is accessed
- **THEN** it MUST return Color.purple

#### Scenario: Reminders appears in available cases
- **WHEN** AdvancedExtensionType.availableCases is accessed
- **THEN** it MUST include the reminders case

### Requirement: Reminders Settings View Integration
AdvancedExtensionsView MUST 支持显示 RemindersSettingsView。

#### Scenario: Reminders settings view is displayed when selected
- **WHEN** user selects reminders extension in AdvancedExtensionsView
- **THEN** the detail pane MUST display RemindersSettingsView

#### Scenario: Reminders appears in extension list
- **WHEN** AdvancedExtensionsView is displayed
- **THEN** the sidebar MUST show reminders extension with its icon and title
