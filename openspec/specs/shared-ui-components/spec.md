## ADDED Requirements

### Requirement: HotKey Recorder Component
The system SHALL provide a reusable HotKeyRecorderView component that can be used across all settings views requiring hotkey input.

#### Scenario: Component displays current hotkey
- **WHEN** a hotkey is configured (keyCode != 0)
- **THEN** the component displays modifier symbols and key character in KeyCap style

#### Scenario: Component opens recorder popover
- **WHEN** user clicks the hotkey button
- **THEN** the system opens a popover for recording new hotkey

#### Scenario: Component detects conflicts
- **WHEN** user records a hotkey that conflicts with existing hotkeys
- **THEN** the component displays conflict message with the conflicting feature name

#### Scenario: Component clears hotkey
- **WHEN** user presses Delete or Backspace in recorder
- **THEN** the component clears the hotkey (sets keyCode and modifiers to 0)

### Requirement: Settings Row Component
The system SHALL provide a reusable SettingsRow component for consistent label-content layout across all settings views.

#### Scenario: Row displays label and content
- **WHEN** a settings row is rendered
- **THEN** the label is right-aligned with configurable width and content is left-aligned

#### Scenario: Row supports custom content
- **WHEN** developer provides ViewBuilder content
- **THEN** the row renders any SwiftUI view as content (TextField, Toggle, Picker, etc.)

### Requirement: KeyCap View Component
The system SHALL provide a reusable KeyCapView component for displaying keyboard keys in a consistent visual style.

#### Scenario: KeyCap displays modifier symbols
- **WHEN** rendering modifier keys (⌘, ⌃, ⌥, ⇧)
- **THEN** the component displays the symbol in a rounded rectangle with accent color background

#### Scenario: KeyCap displays character keys
- **WHEN** rendering character keys (A-Z, 0-9, etc.)
- **THEN** the component displays the character in a rounded rectangle with accent color background

### Requirement: Component Reusability
All shared components MUST be usable in at least 3 different settings views without modification.

#### Scenario: HotKeyRecorder used in multiple views
- **WHEN** BookmarkSearchSettingsView, TwoFactorAuthSettingsView, and other views use HotKeyRecorderView
- **THEN** all views display identical hotkey recording behavior and UI

#### Scenario: SettingsRow used in multiple views
- **WHEN** multiple settings views use SettingsRow with different label widths
- **THEN** each view can configure its own label width while maintaining consistent layout

### Requirement: Component API Consistency
All shared components SHALL follow SwiftUI best practices with @Binding for two-way data flow.

#### Scenario: HotKeyRecorder updates parent state
- **WHEN** user records a new hotkey in HotKeyRecorderView
- **THEN** the parent view's @Binding variables are updated immediately

#### Scenario: SettingsRow passes through content
- **WHEN** developer provides content closure to SettingsRow
- **THEN** the content is rendered without modification using @ViewBuilder

### Requirement: Settings Header Style Consistency
所有高级拓展设置详细页面的头部 MUST 使用统一的 icon 尺寸和标题文字大小。

#### Scenario: Header icon size is consistent
- **WHEN** any advanced extension settings detail page is displayed
- **THEN** the header icon size MUST match the size used in TerminalSettingsView

#### Scenario: Header title font size is consistent
- **WHEN** any advanced extension settings detail page is displayed
- **THEN** the header title font size MUST match the size used in TerminalSettingsView

#### Scenario: All settings pages use same header style
- **WHEN** user navigates between different advanced extension settings pages (Terminal, Clipboard, AI Translate, etc.)
- **THEN** all pages display headers with identical icon size and title font size

### Requirement: Terminal Icon Design
终端设置的 icon MUST 使用更美观的设计。

#### Scenario: Terminal icon is visually appealing
- **WHEN** TerminalSettingsView is displayed
- **THEN** the terminal icon MUST use an improved design that is more visually appealing than the current version

### Requirement: Clipboard Icon Design
剪贴板设置的 icon MUST 使用更美观的设计。

#### Scenario: Clipboard icon is visually appealing
- **WHEN** ClipboardSettingsView is displayed
- **THEN** the clipboard icon MUST use an improved design that is more visually appealing than the current version

### Requirement: Extension Layout in Compact Mode
在简约模式下，扩展界面 MUST 能够正确展开显示，不被限制在输入框区域内。

#### Scenario: Extension expands correctly in compact mode
- **WHEN** user opens an extension (e.g., Zed recent projects) in compact mode
- **THEN** the extension content view expands to full available space and is not constrained within the input box area

#### Scenario: Extension content is fully visible in compact mode
- **WHEN** an extension displays a list of items in compact mode
- **THEN** all list items are visible and not compressed or clipped by input box constraints

#### Scenario: Extension layout matches fullscreen mode behavior
- **WHEN** the same extension is opened in both compact mode and fullscreen mode
- **THEN** the extension content layout behavior is consistent between both modes (only window size differs)

#### Scenario: Multiple extensions work correctly in compact mode
- **WHEN** user opens different extensions (Zed, VSCode, etc.) in compact mode
- **THEN** all extensions display their content correctly without layout issues

### Requirement: Mode Switching with Extension Open
当扩展界面已打开时，在简约模式和全屏模式之间切换 MUST 保持扩展内容的正确显示。

#### Scenario: Switch from compact to fullscreen with extension open
- **WHEN** user switches from compact mode to fullscreen mode while an extension is displayed
- **THEN** the extension content remains visible and adjusts to the new window size without layout errors

#### Scenario: Switch from fullscreen to compact with extension open
- **WHEN** user switches from fullscreen mode to compact mode while an extension is displayed
- **THEN** the extension content remains visible and adjusts to compact mode layout correctly

#### Scenario: Extension state preserved during mode switch
- **WHEN** user switches between modes while interacting with an extension
- **THEN** the extension's scroll position and selection state are preserved
