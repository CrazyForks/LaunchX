import SwiftUI

/// Skills 列表视图
struct SkillListView: View {
    @StateObject private var service = ClaudeSkillService.shared
    @State private var selectedTab: SkillTab = .installed
    @State private var showingRepoSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                // Tab 切换
                Picker("", selection: $selectedTab) {
                    ForEach(SkillTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Spacer()

                if selectedTab == .discover {
                    Button(action: { Task { await service.discoverSkills() } }) {
                        HStack(spacing: 4) {
                            if service.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("刷新")
                        }
                        .font(.system(size: 12))
                    }
                    .disabled(service.isLoading)
                }

                Button(action: { showingRepoSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // 内容
            Group {
                switch selectedTab {
                case .installed:
                    installedListView
                case .discover:
                    discoverListView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showingRepoSettings) {
            SkillRepoSettingsView(isPresented: $showingRepoSettings)
        }
        .onAppear {
            service.initDefaultRepos()
        }
    }

    // MARK: - 已安装列表

    private var installedListView: some View {
        Group {
            if service.skills.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("暂无已安装的 Skill")
                        .foregroundColor(.secondary)
                    Text("切换到「发现」标签浏览和安装 Skills")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(service.skills) { skill in
                            SkillRowView(
                                skill: skill,
                                onToggle: {
                                    try? service.toggleEnabled(skill)
                                },
                                onUninstall: {
                                    try? service.uninstallSkill(skill)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - 发现列表

    private var discoverListView: some View {
        Group {
            if service.discoveredSkills.isEmpty && !service.isLoading {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(service.repos.isEmpty ? "请先添加 Skill 仓库" : "点击「刷新」发现可用 Skills")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(service.discoveredSkills) { discovered in
                            DiscoveredSkillRow(
                                skill: discovered,
                                onInstall: {
                                    try? service.installSkill(discovered)
                                    // 刷新发现列表的安装状态
                                    Task { await service.discoverSkills() }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

enum SkillTab: String, CaseIterable, Identifiable {
    case installed
    case discover

    var id: String { rawValue }
    var title: String {
        switch self {
        case .installed: return "已安装"
        case .discover: return "发现"
        }
    }
}

// MARK: - Skill Row

struct SkillRowView: View {
    let skill: ClaudeSkill
    let onToggle: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { skill.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(.system(size: 13, weight: .medium))
                HStack(spacing: 8) {
                    if !skill.repoFullName.contains("/") {
                        // 只有 repoFullName 是 "/" 时才不显示
                    } else {
                        Text(skill.repoFullName)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Text(skill.directory)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(role: .destructive, action: onUninstall) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .frame(width: 24)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(skill.isEnabled ? Color.accentColor.opacity(0.05) : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - Discovered Skill Row

struct DiscoveredSkillRow: View {
    let skill: ClaudeSkillService.DiscoveredSkill
    let onInstall: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.text")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(.system(size: 13, weight: .medium))
                Text(skill.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(skill.repoOwner + "/" + skill.repoName)
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            if skill.isInstalled {
                Text("已安装")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
            } else {
                Button("安装") {
                    onInstall()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .cornerRadius(6)
    }
}
