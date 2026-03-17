## Why

当前提醒事项功能在应用安装后立即弹出授权请求，这种交互体验不够友好。更重要的是，如果用户在初次安装时拒绝授权，后续没有任何入口可以重新开启这个功能。将提醒事项功能移至高级拓展设置中，可以让用户随时控制是否启用该功能，提供更好的用户体验和控制权。

## What Changes

- 移除应用启动时的提醒事项授权弹窗
- 在高级拓展（AdvancedExtensionsView）中新增"提醒事项"选项
- 创建提醒事项设置视图（RemindersSettingsView），包含开关控制
- 通过开关控制提醒事项功能的启用/禁用和授权请求
- 保持现有的提醒事项功能逻辑不变，仅改变触发授权的时机和入口

## Capabilities

### New Capabilities
- `reminders-settings-ui`: 提醒事项设置界面，包含功能开关、授权状态显示和相关配置选项

### Modified Capabilities
- `shared-ui-components`: 需要在 AdvancedExtensionType 枚举中添加新的提醒事项类型

## Impact

**受影响的组件：**
- `LaunchX/Views/AdvancedExtensionsView.swift` - 需要添加新的提醒事项扩展类型
- `LaunchX/Services/RemindersService.swift` - 可能需要调整授权检查逻辑
- `LaunchX/AppDelegate.swift` 或启动相关代码 - 需要移除初始授权弹窗逻辑
- 需要创建新的 `RemindersSettingsView.swift` 视图文件

**用户体验改进：**
- 用户可以在任何时候通过设置开启或关闭提醒事项功能
- 不再在应用启动时打断用户
- 提供更清晰的功能控制入口

**回滚计划：**
如果新的交互方式导致用户发现率降低，可以通过以下方式回滚：
1. 保留设置入口，但在首次启动时显示引导提示
2. 恢复启动时的授权请求，但添加"稍后设置"选项
