## 1. 创建目录结构

- [x] 1.1 创建 Views/Components/ 目录
- [x] 1.2 创建 Utilities/ 目录
- [x] 1.3 创建 Utilities/Extensions/ 目录
- [x] 1.4 创建 Services/Core/ 目录
- [x] 1.5 创建 Services/Features/ 目录及子目录（Search/, Clipboard/, AITranslate/, Bookmark/）

## 2. 提取共享 UI 组件

- [x] 2.1 创建 Views/Components/HotKeyRecorderView.swift（通用快捷键录制组件）
- [x] 2.2 创建 Views/Components/SettingsRow.swift（通用设置行布局组件）
- [x] 2.3 创建 Views/Components/KeyCapView.swift（通用按键显示组件）
- [ ] 2.4 更新 BookmarkSearchSettingsView 使用 HotKeyRecorderView
- [ ] 2.5 更新 TwoFactorAuthSettingsView 使用 HotKeyRecorderView
- [ ] 2.6 更新所有设置视图使用 SettingsRow
- [ ] 2.7 更新所有快捷键显示使用 KeyCapView
- [ ] 2.8 删除重复的快捷键录制代码
- [ ] 2.9 测试所有设置视图的快捷键功能

## 3. 创建工具类

- [x] 3.1 创建 Utilities/ImageUtils.swift（图标调整、图像处理）
- [x] 3.2 创建 Utilities/KeyCodeUtils.swift（键码转换、快捷键字符串）
- [x] 3.3 创建 Utilities/StringUtils.swift（字符串处理、格式化）
- [x] 3.4 创建 Utilities/ValidationUtils.swift（输入验证、URL 验证）
- [x] 3.5 创建 Utilities/Extensions/NSImage+Resize.swift
- [x] 3.6 创建 Utilities/Extensions/String+Validation.swift
- [x] 3.7 更新 AdvancedExtensionsView 使用 ImageUtils.resizeIcon
- [x] 3.8 更新所有使用 resizeIcon 的视图使用 ImageUtils
- [x] 3.9 更新所有键码转换逻辑使用 KeyCodeUtils
- [x] 3.10 删除重复的工具方法

## 4. 拆分 SearchPanelViewController

- [ ] 4.1 创建 Views/Search/ResultCellView.swift（提取结果单元格视图）
- [ ] 4.2 创建 Views/Search/SearchPanelViewModel.swift（提取搜索状态和业务逻辑）
- [ ] 4.3 创建 Views/Search/SearchPanelViewController+DataSource.swift（提取 NSTableViewDataSource）
- [ ] 4.4 创建 Views/Search/SearchPanelViewController+Delegate.swift（提取各种 Delegate）
- [ ] 4.5 重构 SearchPanelViewController.swift 保留核心控制器逻辑（目标 <500 行）
- [ ] 4.6 更新 import 语句和依赖关系
- [ ] 4.7 测试搜索功能完整性

## 5. 拆分 ToolsSettingsView

- [ ] 5.1 创建 Views/Settings/ToolItemRow.swift（提取工具项行视图）
- [ ] 5.2 创建 Views/Settings/ToolEditorView.swift（提取工具编辑器视图）
- [ ] 5.3 重构 ToolsSettingsView.swift 保留主视图逻辑（目标 <500 行）
- [ ] 5.4 更新 import 语句和依赖关系
- [ ] 5.5 测试工具设置功能

## 6. 拆分 ClipboardPanelViewController

- [ ] 6.1 创建 Views/Clipboard/ClipboardCellView.swift（提取剪贴板单元格视图）
- [ ] 6.2 创建 Views/Clipboard/ClipboardPanelViewController+DataSource.swift（提取 DataSource）
- [ ] 6.3 创建 Views/Clipboard/ClipboardPanelViewController+Delegate.swift（提取 Delegate）
- [ ] 6.4 重构 ClipboardPanelViewController.swift 保留核心逻辑（目标 <500 行）
- [ ] 6.5 更新 import 语句和依赖关系
- [ ] 6.6 测试剪贴板功能

## 7. 拆分 HotKeyService

- [ ] 7.1 创建 Services/Core/HotKeyRegistry.swift（负责快捷键注册和管理）
- [ ] 7.2 创建 Services/Core/HotKeyValidator.swift（负责冲突检测和验证）
- [ ] 7.3 重构 HotKeyService.swift 作为主服务类协调其他组件（目标 <500 行）
- [ ] 7.4 更新所有使用 HotKeyService 的代码
- [ ] 7.5 测试所有快捷键功能

## 8. 拆分 AITranslatePanelViewController

- [ ] 8.1 创建 Views/AITranslate/TranslateCellView.swift（提取翻译单元格视图）
- [ ] 8.2 创建 Views/AITranslate/AITranslatePanelViewController+DataSource.swift
- [ ] 8.3 创建 Views/AITranslate/AITranslatePanelViewController+Delegate.swift
- [ ] 8.4 重构 AITranslatePanelViewController.swift（目标 <500 行）
- [ ] 8.5 测试 AI 翻译功能

## 9. 拆分 AdvancedExtensionsView

- [ ] 9.1 创建 Views/Settings/Extensions/BookmarkSearchSettingsView.swift（独立文件）
- [ ] 9.2 创建 Views/Settings/Extensions/TwoFactorAuthSettingsView.swift（独立文件）
- [ ] 9.3 创建 Views/Settings/Extensions/ClipboardSettingsView.swift（独立文件）
- [ ] 9.4 创建 Views/Settings/Extensions/SnippetSettingsView.swift（独立文件）
- [ ] 9.5 创建 Views/Settings/Extensions/AITranslateSettingsView.swift（独立文件）
- [ ] 9.6 创建 Views/Settings/Extensions/TerminalSettingsView.swift（独立文件）
- [ ] 9.7 重构 AdvancedExtensionsView.swift 仅保留导航逻辑（目标 <200 行）
- [ ] 9.8 测试所有扩展设置

## 10. 重组服务目录结构

- [ ] 10.1 移动 HotKeyService.swift 到 Services/Core/
- [ ] 10.2 移动 PermissionService.swift 到 Services/Core/
- [ ] 10.3 移动 PanelManager.swift 到 Services/Core/
- [ ] 10.4 移动 BookmarkService.swift 到 Services/Features/Bookmark/
- [ ] 10.5 移动 ClipboardService.swift 到 Services/Features/Clipboard/
- [ ] 10.6 移动 AITranslateService.swift 到 Services/Features/AITranslate/
- [ ] 10.7 移动 SearchEngine 相关文件到 Services/Features/Search/
- [ ] 10.8 更新所有 import 语句
- [ ] 10.9 更新 Xcode 项目文件引用

## 11. 代码清理

- [ ] 11.1 搜索并解决所有 TODO 注释
- [ ] 11.2 搜索并解决所有 FIXME 注释
- [ ] 11.3 删除所有注释掉的代码块
- [ ] 11.4 删除未使用的 import 语句
- [ ] 11.5 删除未使用的私有方法
- [ ] 11.6 统一代码风格（缩进、空行、命名）
- [ ] 11.7 整理 import 语句顺序（系统框架优先，按字母排序）

## 12. 测试和验证

- [ ] 12.1 运行完整构建，确保无编译错误
- [ ] 12.2 运行所有现有测试，确保通过
- [ ] 12.3 手动测试搜索功能
- [ ] 12.4 手动测试剪贴板功能
- [ ] 12.5 手动测试 AI 翻译功能
- [ ] 12.6 手动测试书签搜索功能
- [ ] 12.7 手动测试 2FA 短信功能
- [ ] 12.8 手动测试所有快捷键功能
- [ ] 12.9 手动测试所有设置视图
- [ ] 12.10 验证性能无明显下降

## 13. 文档更新

- [ ] 13.1 创建文件迁移指南（旧路径 → 新路径映射表）
- [ ] 13.2 更新 README.md 中的项目结构说明
- [ ] 13.3 更新开发文档中的架构说明
- [ ] 13.4 记录重构过程中的关键决策
