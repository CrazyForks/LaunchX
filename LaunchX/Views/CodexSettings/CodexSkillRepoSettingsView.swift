import SwiftUI

/// Codex Skill 仓库管理界面
struct CodexSkillRepoSettingsView: View {
    @Binding var isPresented: Bool
    @StateObject private var service = CodexSkillService.shared
    @State private var newOwner: String = ""
    @State private var newName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Text("Skill 仓库管理")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            // 添加仓库
            HStack {
                TextField("owner", text: $newOwner)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                Text("/")
                    .foregroundColor(.secondary)
                TextField("repo", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                Button("添加") {
                    if !newOwner.isEmpty && !newName.isEmpty {
                        service.addRepo(owner: newOwner, name: newName)
                        newOwner = ""
                        newName = ""
                    }
                }
                .disabled(newOwner.isEmpty || newName.isEmpty)
            }
            .padding(16)

            Divider()

            // 仓库列表
            if service.repos.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Text("暂无仓库")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(service.repos) { repo in
                            HStack {
                                Toggle("", isOn: Binding(
                                    get: { repo.isEnabled },
                                    set: { _ in
                                        if let index = service.repos.firstIndex(where: { $0.id == repo.id }) {
                                            service.repos[index].isEnabled.toggle()
                                            try? CodexDataStore.shared.saveSkillRepos(service.repos)
                                        }
                                    }
                                ))
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .labelsHidden()

                                Text(repo.fullName)
                                    .font(.system(size: 13))

                                Spacer()

                                Button(action: { service.removeRepo(repo) }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("关闭") { isPresented = false }
            }
            .padding(16)
        }
        .frame(width: 380, height: 400)
    }
}
