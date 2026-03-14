import Carbon
import SwiftUI

// MARK: - 高级扩展类型

enum AdvancedExtensionType: String, CaseIterable, Identifiable {
    case clipboard = "剪贴板"
    case snippet = "Snippet"
    case aiTranslate = "AI 翻译"
    case bookmarkSearch = "搜索书签"
    case twoFactorAuth = "2FA 短信"
    case terminal = "终端"

    var id: String { rawValue }

    /// 判断是否运行在 macOS 26 或更高版本
    private static var isMacOS26OrLater: Bool {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26
    }

    /// 获取当前系统可用的扩展类型（macOS 26+ 不显示 2FA 短信，因为系统已原生支持）
    static var availableCases: [AdvancedExtensionType] {
        if isMacOS26OrLater {
            return allCases.filter { $0 != .twoFactorAuth }
        }
        return allCases
    }

    /// 资源图标名称（返回 nil 表示使用 SF Symbol）
    var iconImageName: String? {
        return nil  // 全部使用 SF Symbol 以保持风格统一
    }

    /// SF Symbol 名称（用于没有自定义图标的扩展）
    var sfSymbolName: String {
        switch self {
        case .clipboard: return "doc.on.clipboard"
        case .snippet: return "chevron.left.forwardslash.chevron.right"
        case .aiTranslate: return "character.bubble.fill"
        case .bookmarkSearch: return "bookmark.fill"
        case .twoFactorAuth: return "lock.shield.fill"
        case .terminal: return "terminal"
        }
    }

    /// 图标颜色
    var iconColor: Color {
        switch self {
        case .clipboard: return .blue
        case .snippet: return .orange
        case .aiTranslate: return .indigo
        case .bookmarkSearch: return .pink
        case .twoFactorAuth: return .green
        case .terminal: return .blue
        }
    }
}

// MARK: - 高级扩展设置视图

struct AdvancedExtensionsView: View {
    @State private var selectedExtension: AdvancedExtensionType = .clipboard

    var body: some View {
        HSplitView {
            // 左侧：扩展列表
            extensionList
                .frame(minWidth: 180, maxWidth: 200)

            // 右侧：扩展设置
            extensionSettings
                .frame(minWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 左侧扩展列表

    private var extensionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(AdvancedExtensionType.availableCases) { type in
                ExtensionSidebarItem(
                    type: type,
                    isSelected: selectedExtension == type
                ) {
                    selectedExtension = type
                }
            }
            Spacer()
        }
        .padding(.top, 12)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - 右侧扩展设置

    @ViewBuilder
    private var extensionSettings: some View {
        switch selectedExtension {
        case .bookmarkSearch:
            BookmarkSearchSettingsView()
        case .clipboard:
            ClipboardSettingsView()
        case .snippet:
            SnippetSettingsView()
        case .twoFactorAuth:
            TwoFactorAuthSettingsView()
        case .aiTranslate:
            AITranslateSettingsView()
        case .terminal:
            TerminalSettingsView()
        }
    }
}

// MARK: - 即将推出占位视图

struct ComingSoonView: View {
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.medium)

            Text(description)
                .foregroundColor(.secondary)

            Text("即将推出")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .foregroundColor(.orange)
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 书签搜索设置视图

struct BookmarkSearchSettingsView: View {
    @State private var settings = BookmarkSettings.load()
    @State private var bookmarkCount: Int = 0
    @State private var safariAccessible: Bool = true
    @State private var showHotKeyPopover: Bool = false
    @State private var selectedOption: BookmarkOpenWithOption = .special(.defaultBrowser)

    private let labelWidth: CGFloat = 140

    // 动态生成可用的打开浏览器选项
    private var availableOpenWithOptions: [BookmarkOpenWithOption] {
        var options: [BookmarkOpenWithOption] = [
            .special(.bookmarkBrowser),
            .special(.defaultBrowser)
        ]

        // 添加已安装的浏览器
        for source in BookmarkSource.allCases where source.isInstalled {
            options.append(.browser(source))
        }

        return options
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 标题行：图标 + 名称 + 开关（所有高级扩展都使用这种统一样式）
                HStack(spacing: 12) {
                    Image(systemName: AdvancedExtensionType.bookmarkSearch.sfSymbolName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(AdvancedExtensionType.bookmarkSearch.iconColor)
                    Text("搜索书签")
                        .font(.headline)
                    Spacer()

                    // 启用开关
                    Toggle("", isOn: $settings.isEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: settings.isEnabled) { _, _ in
                            settings.save()
                        }
                }

                Divider()

                // 快捷键设置（所有高级扩展的快捷键都使用这种统一样式）
                HStack {
                    Text("直接打开扩展快捷键:")
                        .frame(width: labelWidth, alignment: .trailing)
                    ExtensionHotKeyButton(
                        keyCode: $settings.hotKeyCode,
                        modifiers: $settings.hotKeyModifiers,
                        showPopover: $showHotKeyPopover
                    )
                    .popover(isPresented: $showHotKeyPopover) {
                        ExtensionHotKeyRecorderPopover(
                            keyCode: $settings.hotKeyCode,
                            modifiers: $settings.hotKeyModifiers,
                            isPresented: $showHotKeyPopover,
                            exampleKey: "B",
                            onSave: { settings.save() },
                            onUnregister: { HotKeyService.shared.unregisterBookmarkHotKey() },
                            onRegister: { keyCode, modifiers in
                                HotKeyService.shared.registerBookmarkHotKey(keyCode: keyCode, modifiers: modifiers)
                            },
                            checkConflict: { keyCode, modifiers in
                                HotKeyService.shared.checkConflict(
                                    keyCode: keyCode,
                                    modifiers: modifiers,
                                    excludingMainHotKey: false
                                )
                            }
                        )
                    }
                    Spacer()
                }

                // 别名
                HStack {
                    Text("别名:")
                        .frame(width: labelWidth, alignment: .trailing)
                    TextField("bk", text: $settings.alias)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onChange(of: settings.alias) { _, _ in
                            settings.save()
                        }
                    Spacer()
                }

                // 打开浏览器
                HStack {
                    Text("打开浏览器:")
                        .frame(width: labelWidth, alignment: .trailing)
                    Picker("", selection: $selectedOption) {
                        ForEach(availableOpenWithOptions, id: \.id) { option in
                            HStack(spacing: 6) {
                                Image(nsImage: ImageUtils.resizeIcon(option.icon, to: 16))
                                Text(option.displayName)
                            }
                            .tag(option)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 150)
                    .onChange(of: selectedOption) { _, newValue in
                        settings.openWith = newValue.toBookmarkOpenWith()
                        settings.save()
                    }
                    Spacer()
                }

                Divider()

                // 搜索浏览器
                VStack(alignment: .leading, spacing: 10) {
                    Text("搜索浏览器")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    // 动态显示已安装的浏览器
                    ForEach(BookmarkSource.allCases.filter { $0.isInstalled }, id: \.self) { source in
                        BrowserToggleRow(
                            source: source,
                            isEnabled: settings.enabledSources.contains(source),
                            isAccessible: source == .safari ? safariAccessible : true
                        ) { enabled in
                            updateSourceEnabled(source, enabled: enabled)
                        }
                    }

                    // 书签统计和刷新
                    HStack {
                        Text("已索引书签: \(bookmarkCount) 个")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("刷新") {
                            refreshBookmarks()
                        }
                        .font(.caption)
                    }
                    .padding(.top, 4)
                }

                // 权限提示
                if !safariAccessible {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("需要完全磁盘访问权限才能读取 Safari 书签")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("打开设置") {
                            openFullDiskAccessSettings()
                        }
                        .font(.caption)
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding(20)
        }
        .onAppear {
            checkAccess()
            refreshBookmarks()
            // 从 settings.openWith 初始化 selectedOption
            selectedOption = BookmarkOpenWithOption.from(settings.openWith)
        }
    }

    private func updateSourceEnabled(_ source: BookmarkSource, enabled: Bool) {
        if enabled {
            if !settings.enabledSources.contains(source) {
                settings.enabledSources.append(source)
            }
        } else {
            settings.enabledSources.removeAll { $0 == source }
        }
        settings.save()
        refreshBookmarks()
    }

    private func checkAccess() {
        safariAccessible = BookmarkService.shared.checkFullDiskAccess()
    }

    private func refreshBookmarks() {
        BookmarkService.shared.clearCache()
        let bookmarks = BookmarkService.shared.getAllBookmarks(forceReload: true)
        bookmarkCount = bookmarks.count
    }

    private func openFullDiskAccessSettings() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
        {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - 浏览器开关行

struct BrowserToggleRow: View {
    let source: BookmarkSource
    let isEnabled: Bool
    let isAccessible: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Toggle(
                "",
                isOn: Binding(
                    get: { isEnabled },
                    set: { onToggle($0) }
                )
            )
            .toggleStyle(.checkbox)
            .disabled(!isAccessible)

            Image(nsImage: source.icon)

            Text(source.displayName)
                .font(.system(size: 13))
                .opacity(isAccessible ? 1 : 0.5)

            if !isAccessible {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 扩展侧边栏项

struct ExtensionSidebarItem: View {
    let iconImageName: String?
    let sfSymbolName: String
    let iconColor: Color
    let title: String
    let isSelected: Bool
    let action: () -> Void

    init(
        type: AdvancedExtensionType,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.iconImageName = type.iconImageName
        self.sfSymbolName = type.sfSymbolName
        self.iconColor = type.iconColor
        self.title = type.rawValue
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: sfSymbolName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                    .foregroundColor(iconColor)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .padding(.horizontal, 8)
    }
}

// MARK: - 2FA 短信设置视图

struct TwoFactorAuthSettingsView: View {
    @State private var settings = TwoFactorAuthSettings.load()
    @State private var showHotKeyPopover = false
    @State private var hasFullDiskAccess = false
    @State private var recentCodesCount = 0

    private let labelWidth: CGFloat = 140

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 标题行：图标 + 名称 + 开关（所有高级扩展都使用这种统一样式）
                HStack(spacing: 12) {
                    Image(systemName: AdvancedExtensionType.twoFactorAuth.sfSymbolName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(AdvancedExtensionType.twoFactorAuth.iconColor)
                    Text("2FA 短信")
                        .font(.headline)
                    Spacer()

                    // 启用开关
                    Toggle("", isOn: $settings.isEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: settings.isEnabled) { _, _ in
                            settings.save()
                        }
                }

                Divider()

                // 快捷键设置（所有高级扩展的快捷键都使用这种统一样式）
                HStack {
                    Text("直接打开扩展快捷键:")
                        .frame(width: labelWidth, alignment: .trailing)
                    ExtensionHotKeyButton(
                        keyCode: $settings.hotKeyCode,
                        modifiers: $settings.hotKeyModifiers,
                        showPopover: $showHotKeyPopover
                    )
                    .popover(isPresented: $showHotKeyPopover) {
                        ExtensionHotKeyRecorderPopover(
                            keyCode: $settings.hotKeyCode,
                            modifiers: $settings.hotKeyModifiers,
                            isPresented: $showHotKeyPopover,
                            exampleKey: "2",
                            onSave: { settings.save() },
                            onUnregister: { HotKeyService.shared.unregister2FAHotKey() },
                            onRegister: { keyCode, modifiers in
                                HotKeyService.shared.register2FAHotKey(keyCode: keyCode, modifiers: modifiers)
                            },
                            checkConflict: { keyCode, modifiers in
                                HotKeyService.shared.checkHotKeyConflict(
                                    keyCode: keyCode,
                                    modifiers: modifiers,
                                    excludeType: "2fa"
                                )
                            }
                        )
                    }
                    Spacer()
                }

                // 别名
                HStack {
                    Text("别名:")
                        .frame(width: labelWidth, alignment: .trailing)
                    TextField("2fa", text: $settings.alias)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onChange(of: settings.alias) { _, _ in
                            settings.save()
                        }
                    Spacer()
                }

                // 时间范围
                HStack {
                    Text("搜索时间范围:")
                        .frame(width: labelWidth, alignment: .trailing)
                    Picker("", selection: $settings.timeSpanMinutes) {
                        Text("最近 5 分钟").tag(5)
                        Text("最近 10 分钟").tag(10)
                        Text("最近 30 分钟").tag(30)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 150)
                    .onChange(of: settings.timeSpanMinutes) { _, _ in
                        settings.save()
                        refreshCodesCount()
                    }
                    Spacer()
                }

                // 复制后删除短信
                HStack {
                    Text("复制后删除短信:")
                        .frame(width: labelWidth, alignment: .trailing)
                    Toggle("", isOn: $settings.deleteAfterCopy)
                        .toggleStyle(.switch)
                        .onChange(of: settings.deleteAfterCopy) { _, _ in
                            settings.save()
                        }
                    Text("因苹果限制，做不到无感删除，复制后屏幕上会有2s的自动操作，且该操作将删除该发送者的整个对话！")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }

                Divider()

                // 权限状态
                VStack(alignment: .leading, spacing: 10) {
                    Text("权限状态")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 8) {
                        Image(
                            systemName: hasFullDiskAccess
                                ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundColor(hasFullDiskAccess ? .green : .red)
                        Text("完全磁盘访问")
                            .font(.system(size: 13))
                        if !hasFullDiskAccess {
                            Spacer()
                            Button("授权") {
                                openFullDiskAccessSettings()
                            }
                            .font(.caption)
                        }
                    }

                    if hasFullDiskAccess {
                        HStack {
                            Text("已找到验证码: \(recentCodesCount) 个")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("刷新") {
                                refreshCodesCount()
                            }
                            .font(.caption)
                        }
                        .padding(.top, 4)
                    }
                }

                Divider()

                // iPhone 短信转发设置指南
                VStack(alignment: .leading, spacing: 10) {
                    Text("iPhone 短信转发设置")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 8) {
                        SetupStepRow(step: 1, text: "确保 iPhone 和 Mac 登录同一 Apple ID")
                        SetupStepRow(step: 2, text: "iPhone: 设置 → 信息 → 短信转发")
                        SetupStepRow(step: 3, text: "开启此 Mac 的短信转发开关")
                        SetupStepRow(step: 4, text: "Mac: 打开「信息」应用，确保已登录")
                    }

                    Button("打开「信息」应用") {
                        NSWorkspace.shared.open(URL(string: "messages://")!)
                    }
                    .font(.caption)
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding(20)
        }
        .onAppear {
            checkPermissions()
            refreshCodesCount()
        }
    }

    private func checkPermissions() {
        hasFullDiskAccess = TwoFactorAuthService.shared.checkFullDiskAccess()
    }

    private func refreshCodesCount() {
        guard hasFullDiskAccess else {
            recentCodesCount = 0
            return
        }
        let codes = TwoFactorAuthService.shared.getRecentCodes(
            timeSpanMinutes: settings.timeSpanMinutes)
        recentCodesCount = codes.count
    }

    private func openFullDiskAccessSettings() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
        {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - 设置步骤行

struct SetupStepRow: View {
    let step: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(step).")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16, alignment: .trailing)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AdvancedExtensionsView()
        .frame(width: 700, height: 500)
}
