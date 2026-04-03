## ADDED Requirements

### Requirement: Extension Mode Switching Race Safety
当通过快捷键连续在不同扩展模式之间快速切换时，系统 MUST 保证模式切换的原子性和一致性，不允许出现界面显示错误（如一个扩展的界面展示了另一个扩展的内容）。

#### Scenario: Rapid switch from custom extension to ClaudeCode
- **WHEN** 用户先按快捷键进入自定义扩展 A，然后在极短时间内（< 0.2 秒）按快捷键进入 ClaudeCode 扩展
- **THEN** 面板最终 MUST 正确显示 ClaudeCode 扩展的内容，不出现自定义扩展 A 的残留内容

#### Scenario: Rapid switch from ClaudeCode to custom extension
- **WHEN** 用户先按快捷键进入 ClaudeCode 扩展，然后在极短时间内按快捷键进入自定义扩展 B
- **THEN** 面板最终 MUST 正确显示自定义扩展 B 的内容，不出现 ClaudeCode 的残留内容

#### Scenario: Multiple rapid switches
- **WHEN** 用户在 1 秒内连续按多个不同扩展的快捷键 3 次以上
- **THEN** 面板最终 MUST 正确显示最后一次快捷键对应的扩展内容，且中间过程不出现内容混合

#### Scenario: ClaudeCode mode entry is synchronous
- **WHEN** ClaudeCode 扩展的快捷键通知 `handleEnterClaudeCodeModeDirectly` 被触发
- **THEN** 模式切换 MUST 同步完成，不使用 asyncAfter 等异步延迟

### Requirement: File Size Limits
The system SHALL enforce a maximum file size of 500 lines per Swift file.

#### Scenario: New files comply with size limit
- **WHEN** a new Swift file is created
- **THEN** the file MUST NOT exceed 500 lines of code

#### Scenario: Existing large files are split
- **WHEN** refactoring existing files over 500 lines
- **THEN** the file MUST be split into multiple files with clear responsibilities

#### Scenario: Extension files for large classes
- **WHEN** a class requires more than 500 lines
- **THEN** the class MUST be split using extension files (e.g., ViewController+DataSource.swift)

### Requirement: Directory Structure Organization
The system SHALL organize code files into a clear hierarchical directory structure by feature domain.

#### Scenario: Views organized by feature
- **WHEN** organizing view files
- **THEN** views MUST be grouped under Views/<Feature>/ directories (e.g., Views/Search/, Views/Clipboard/)

#### Scenario: Services organized by type
- **WHEN** organizing service files
- **THEN** services MUST be grouped under Services/Core/ or Services/Features/<Feature>/ directories

#### Scenario: Shared components in dedicated directory
- **WHEN** creating reusable UI components
- **THEN** components MUST be placed in Views/Components/ directory

#### Scenario: Utilities in dedicated directory
- **WHEN** creating utility classes
- **THEN** utilities MUST be placed in Utilities/ directory with optional subdirectories (e.g., Utilities/Extensions/)

### Requirement: Single Responsibility Principle
Each Swift file SHALL have a single, well-defined responsibility.

#### Scenario: ViewController contains only coordination logic
- **WHEN** implementing a ViewController
- **THEN** the file MUST contain only view lifecycle and coordination logic, delegating data source and delegate implementations to extensions

#### Scenario: DataSource in separate extension file
- **WHEN** implementing NSTableViewDataSource or NSCollectionViewDataSource
- **THEN** the implementation MUST be in a separate extension file (e.g., ViewController+DataSource.swift)

#### Scenario: Delegate in separate extension file
- **WHEN** implementing delegate protocols
- **THEN** the implementation MUST be in a separate extension file (e.g., ViewController+Delegate.swift)

#### Scenario: Service classes have single purpose
- **WHEN** implementing a service class
- **THEN** the class MUST handle only one domain responsibility (e.g., HotKeyRegistry handles registration, HotKeyValidator handles validation)

### Requirement: Code Reusability
The system SHALL eliminate code duplication by extracting common patterns into shared components and utilities.

#### Scenario: No duplicate UI components
- **WHEN** the same UI pattern appears in 2+ views
- **THEN** the pattern MUST be extracted into a shared component in Views/Components/

#### Scenario: No duplicate utility methods
- **WHEN** the same utility method appears in 2+ files
- **THEN** the method MUST be extracted into a utility class in Utilities/

#### Scenario: No duplicate validation logic
- **WHEN** the same validation logic appears in 2+ places
- **THEN** the logic MUST be extracted into ValidationUtils

### Requirement: Clear Module Boundaries
The system SHALL maintain clear boundaries between modules with explicit dependencies.

#### Scenario: Core services independent of features
- **WHEN** implementing core services (HotKeyService, PermissionService)
- **THEN** core services MUST NOT depend on feature-specific code

#### Scenario: Feature services depend only on core
- **WHEN** implementing feature services (BookmarkService, ClipboardService)
- **THEN** feature services MAY depend on core services but NOT on other feature services

#### Scenario: Views depend on services via protocols
- **WHEN** views need to access services
- **THEN** views SHOULD depend on service protocols rather than concrete implementations where possible

### Requirement: File Naming Conventions
The system SHALL follow consistent file naming conventions across the codebase.

#### Scenario: Extension files use plus notation
- **WHEN** creating extension files for a class
- **THEN** the file MUST be named ClassName+ExtensionPurpose.swift (e.g., SearchPanelViewController+DataSource.swift)

#### Scenario: Component files use descriptive names
- **WHEN** creating shared components
- **THEN** the file MUST be named with the component purpose (e.g., HotKeyRecorderView.swift, SettingsRow.swift)

#### Scenario: Utility files use Utils suffix
- **WHEN** creating utility classes
- **THEN** the file MUST be named with Utils suffix (e.g., ImageUtils.swift, KeyCodeUtils.swift)

#### Scenario: Service files use Service suffix
- **WHEN** creating service classes
- **THEN** the file MUST be named with Service suffix (e.g., BookmarkService.swift, ClipboardService.swift)

### Requirement: Import Statement Organization
The system SHALL organize import statements consistently across all files.

#### Scenario: System frameworks imported first
- **WHEN** a file has multiple imports
- **THEN** system frameworks (Foundation, AppKit, SwiftUI) MUST be imported before third-party frameworks

#### Scenario: Imports sorted alphabetically
- **WHEN** a file has multiple imports in the same category
- **THEN** imports MUST be sorted alphabetically within their category

### Requirement: Code Cleanup
The system SHALL remove all unused code, comments, and obsolete implementations.

#### Scenario: No TODO comments
- **WHEN** refactoring is complete
- **THEN** all TODO comments MUST be resolved or removed

#### Scenario: No FIXME comments
- **WHEN** refactoring is complete
- **THEN** all FIXME comments MUST be resolved or removed

#### Scenario: No commented-out code
- **WHEN** refactoring is complete
- **THEN** all commented-out code blocks MUST be removed

#### Scenario: No unused imports
- **WHEN** a file is refactored
- **THEN** all unused import statements MUST be removed

#### Scenario: No unused methods
- **WHEN** a file is refactored
- **THEN** all unused private methods MUST be removed
