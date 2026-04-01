## 1. 数据模型重构

- [x] 1.1 重构 BackupModel：移除 GeneralSettings，新增全部 8 个高级模块配置字段（clipboardSettings、bookmarkSettings、twoFactorAuthSettings、terminalSettings、remindersSettings、claudeCodeSwitcherSettings），版本号更新为 "2.0"
- [x] 1.2 更新 BackupModel.createCurrent() 方法，收集全部 8 个模块的当前设置
- [x] 1.3 更新 BackupModel.apply() 方法，逐一调用各模块 save()，移除 generalSettings 还原逻辑，保留 Snippet 文件写入和全局通知
- [x] 1.4 添加版本校验：在 BackupModel 解码时检查 metadata.version，拒绝非 "2.0" 格式的文件

## 2. UI 迁移

- [x] 2.1 从 GeneralSettingsView（SettingsView.swift）移除「配置备份」区域（导入/导出按钮及相关 HStack）
- [x] 2.2 在 AdvancedExtensionsView 左侧扩展列表底部添加分割线 + 导入/导出按钮区域
- [x] 2.3 调整导入确认对话框的提示文案，明确说明将覆盖高级扩展配置

## 3. 服务层更新

- [x] 3.1 更新 BackupService.exportConfiguration() 中的默认文件名和成功提示文案
- [x] 3.2 更新 BackupService.importConfiguration() 中的确认对话框文案和错误提示

## 4. 验证

- [x] 4.1 编译确认无错误
