import AppKit
import SwiftUI

/// 设置页面顶部样式常量
enum SettingsHeaderStyle {
    /// 图标尺寸（字体大小）
    static let iconSize: CGFloat = 20

    /// 图标固定 frame 尺寸（确保所有图标占用相同空间）
    static let iconFrameSize: CGFloat = 24

    /// 图标和标题之间的间距
    static let iconTitleSpacing: CGFloat = 12

    /// 标题字体
    static let titleFont: Font = .title2

    /// 标题字重
    static let titleFontWeight: Font.Weight = .bold

    /// 水平内边距
    static let horizontalPadding: CGFloat = 20

    /// 顶部内边距
    static let topPadding: CGFloat = 20

    /// 底部内边距
    static let bottomPadding: CGFloat = 16
}

/// 扩展设置页顶部的图标，与侧边栏 `ExtensionSidebarItem` 的图标保持一致：
/// 优先级为「品牌 logo > 系统 App 图标 > 带颜色的 SF Symbol」，统一固定 frame 尺寸。
/// 用法：`ExtensionHeaderIcon(type: .reminders)`
struct ExtensionHeaderIcon: View {
    let type: AdvancedExtensionType

    var body: some View {
        Group {
            if let name = type.iconImageName, let logo = NSImage(named: name) {
                Image(nsImage: logo)
                    .resizable()
                    .scaledToFit()
            } else if let appIcon = type.systemAppBundleId.flatMap({
                AdvancedExtensionType.systemAppIcon(forBundleId: $0)
            }) {
                Image(nsImage: appIcon)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: type.sfSymbolName)
                    .font(.system(size: SettingsHeaderStyle.iconSize))
                    .foregroundColor(type.iconColor)
            }
        }
        .frame(width: SettingsHeaderStyle.iconFrameSize, height: SettingsHeaderStyle.iconFrameSize)
    }
}

