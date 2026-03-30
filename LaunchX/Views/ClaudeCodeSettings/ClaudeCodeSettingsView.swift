import SwiftUI

/// Claude Code 管理主视图
struct ClaudeCodeSettingsView: View {
    @StateObject private var providerService = ClaudeProviderService.shared
    @State private var selectedTab: ClaudeCodeTab = .providers

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("Claude Code 设置")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Tab 切换
            HStack(spacing: 0) {
                ForEach(ClaudeCodeTab.allCases) { tab in
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
                    ProviderListView()
                case .mcp:
                    McpServerListView()
                case .skills:
                    SkillListView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // 首次导入
            if providerService.providers.isEmpty {
                providerService.importDefaultConfig()
            }
        }
    }
}

enum ClaudeCodeTab: String, CaseIterable, Identifiable {
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
    ClaudeCodeSettingsView()
        .frame(width: 480, height: 500)
}
