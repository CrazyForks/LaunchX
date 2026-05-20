import SwiftUI

/// Codex Skills 列表视图
struct CodexSkillListView: View {
    @StateObject private var service = CodexSkillService.shared
    @State private var selectedTab: CodexSkillTab = .installed
    @State private var showingRepoSettings = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("", selection: $selectedTab) {
                    ForEach(CodexSkillTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                Spacer()

                if selectedTab == .discover {
                    Button(action: { Task { await service.discoverSkills() } }) {
                        HStack(spacing: 4) {
                            if service.isLoading {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("刷新")
                        }
                        .font(.system(size: 12))
                    }
                    .disabled(service.isLoading)
                }

                if selectedTab == .installed {
                    Button(action: {
                        let unmanaged = service.scanUnmanagedSkills()
                        for skill in unmanaged {
                            try? service.importSkill(skill)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down")
                            Text("从 .agents 导入")
                        }
                        .font(.system(size: 12))
                    }
                }

                Button(action: { showingRepoSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

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
            CodexSkillRepoSettingsView(isPresented: $showingRepoSettings)
        }
        .onAppear {
            service.initDefaultRepos()
        }
    }

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
                            CodexSkillRowView(
                                skill: skill,
                                onToggle: { try? service.toggleEnabled(skill) },
                                onUninstall: { try? service.uninstallSkill(skill) }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
    }

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
                            CodexDiscoveredSkillRow(
                                skill: discovered,
                                onInstall: {
                                    Task {
                                        try? await service.installSkill(discovered)
                                        await service.discoverSkills()
                                    }
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

enum CodexSkillTab: String, CaseIterable, Identifiable {
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

struct CodexSkillRowView: View {
    let skill: CodexSkill
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
                    Text(skill.repoFullName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(skill.isEnabled ? Color.orange.opacity(0.05) : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - Discovered Skill Row

struct CodexDiscoveredSkillRow: View {
    let skill: CodexDiscoveredSkill
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
                if let desc = skill.description {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(skill.repoOwner + "/" + skill.repoName)
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Button("安装") { onInstall() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .cornerRadius(6)
    }
}
