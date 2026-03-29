import SwiftUI

/// Skill 仓库管理视图
struct SkillRepoSettingsView: View {
    @Binding var isPresented: Bool
    @StateObject private var service = ClaudeSkillService.shared
    @State private var newOwner: String = ""
    @State private var newName: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Skill 仓库管理")
                .font(.headline)

            // 添加仓库
            HStack(spacing: 8) {
                TextField("Owner", text: $newOwner)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                Text("/")
                    .foregroundColor(.secondary)
                TextField("Repo Name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
                Button("添加") {
                    if !newOwner.isEmpty && !newName.isEmpty {
                        service.addRepo(owner: newOwner, name: newName)
                        newOwner = ""
                        newName = ""
                    }
                }
                .disabled(newOwner.isEmpty || newName.isEmpty)
            }

            Divider()

            // 仓库列表
            if service.repos.isEmpty {
                Text("暂无仓库配置")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(service.repos) { repo in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(repo.idString)
                                    .font(.system(size: 13))
                                Text("分支: \(repo.branch)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { repo.isEnabled },
                                set: { _ in
                                    if let index = service.repos.firstIndex(where: { $0.id == repo.id }) {
                                        service.repos[index].isEnabled.toggle()
                                        try? ClaudeDataStore.shared.saveSkillRepos(service.repos)
                                    }
                                }
                            ))
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .labelsHidden()

                            Button(role: .destructive) {
                                service.removeRepo(repo)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset)
            }

            Spacer()

            HStack {
                Spacer()
                Button("完成") { isPresented = false }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 450, height: 380)
    }
}
