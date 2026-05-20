import SwiftUI

/// Codex CLI 管理主视图
struct CodexSettingsView: View {
    @StateObject private var providerService = CodexProviderService.shared
    @State private var selectedTab: CodexTab = .providers
    @State private var settings = CodexSwitcherSettings.load()
    @State private var showHotKeyPopover: Bool = false

    private let labelWidth: CGFloat = 140

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 标准头部
                HStack(spacing: SettingsHeaderStyle.iconTitleSpacing) {
                    Image(systemName: "cpu")
                        .font(.system(size: SettingsHeaderStyle.iconSize))
                        .foregroundColor(.orange)
                        .frame(width: SettingsHeaderStyle.iconFrameSize, height: SettingsHeaderStyle.iconFrameSize)
                    Text("Codex CLI")
                        .font(SettingsHeaderStyle.titleFont)
                        .fontWeight(SettingsHeaderStyle.titleFontWeight)
                    Spacer()

                    Toggle("", isOn: $settings.isEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: settings.isEnabled) { _, _ in
                            settings.save()
                        }
                }
                .padding(.horizontal, SettingsHeaderStyle.horizontalPadding)
                .padding(.top, SettingsHeaderStyle.topPadding)
                .padding(.bottom, SettingsHeaderStyle.bottomPadding)

                Divider()

                // 快捷键行
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
                            exampleKey: "X",
                            onSave: { settings.save() },
                            onUnregister: { HotKeyService.shared.unregisterCodexHotKey() },
                            onRegister: { keyCode, modifiers in
                                HotKeyService.shared.registerCodexHotKey(keyCode: keyCode, modifiers: modifiers)
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
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // 别名行
                HStack {
                    Text("别名:")
                        .frame(width: labelWidth, alignment: .trailing)
                    TextField("cx", text: $settings.alias)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onChange(of: settings.alias) { _, _ in
                            settings.save()
                        }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Divider()
                    .padding(.top, 16)

                // Tab 切换
                HStack(spacing: 0) {
                    ForEach(CodexTab.allCases) { tab in
                        Button(action: { selectedTab = tab }) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.iconName)
                                    .font(.system(size: 12))
                                Text(tab.title)
                                    .font(.system(size: 13))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                            .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Divider()
                    .padding(.top, 8)

                // 内容区
                Group {
                    switch selectedTab {
                    case .providers:
                        CodexProviderListView()
                    case .mcp:
                        CodexMcpServerListView()
                    case .skills:
                        CodexSkillListView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if providerService.providers.isEmpty {
                providerService.importDefaultConfig()
            }
        }
    }
}

enum CodexTab: String, CaseIterable, Identifiable {
    case providers
    case mcp
    case skills

    var id: String { rawValue }

    var title: String {
        switch self {
        case .providers: return "Provider"
        case .mcp: return "MCP"
        case .skills: return "Skills"
        }
    }

    var iconName: String {
        switch self {
        case .providers: return "server.rack"
        case .mcp: return "puzzlepiece.extension"
        case .skills: return "wand.and.stars"
        }
    }
}

#Preview {
    CodexSettingsView()
        .frame(width: 480, height: 500)
}
