import SwiftUI

/// Codex MCP 服务器添加/编辑表单
/// Codex 的 MCP 配置存于 ~/.codex/config.toml（TOML），因此这里原生使用 TOML 输入，
/// 与 Claude 表单（JSON）区分开。
struct CodexMcpFormView: View {
    @Binding var isPresented: Bool
    @StateObject private var service = ClaudeMcpService.shared
    var editingServer: McpServer?

    @State private var name: String = ""
    @State private var configToml: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Image(systemName: "puzzlepiece.extension")
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
                Text(editingServer != nil ? "编辑 Codex MCP" : "添加 Codex MCP")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text("名称")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 36, alignment: .trailing)
                    TextField("例如：filesystem", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                }

                VStack(alignment: .leading, spacing: 4) {
                    TextEditor(text: $configToml)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(minHeight: 180)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                        )

                    HStack {
                        Text("TOML 格式的服务端配置（可含 [mcp_servers.<名称>] 表头）")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("格式化") { formatToml() }
                            .font(.system(size: 11))
                            .controlSize(.small)
                    }

                    if let error = errorMessage {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(16)

            Spacer()

            Divider()

            HStack {
                Spacer()
                Button("取消") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button(editingServer != nil ? "保存" : "添加") { saveServer() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(configToml.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 480, height: 400)
        .onAppear {
            if let server = editingServer {
                name = server.name
                configToml = service.renderTomlBody(server.serverConfig)
            } else {
                configToml = """
                command = "npx"
                args = ["-y", "@modelcontextprotocol/server-filesystem"]
                """
            }
        }
    }

    private func formatToml() {
        guard let (_, config) = service.parseCodexMcpToml(configToml) else {
            errorMessage = "无效的 TOML 格式"
            return
        }
        errorMessage = nil
        configToml = service.renderTomlBody(config)
    }

    private func saveServer() {
        guard let parsed = service.parseCodexMcpToml(configToml) else {
            errorMessage = "无效的 TOML 格式"
            return
        }

        // 名称优先取输入框，为空时回退到 TOML 表头
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let finalName = trimmedName.isEmpty ? (parsed.name ?? "") : trimmedName
        if finalName.isEmpty {
            errorMessage = "请填写名称"
            return
        }
        name = finalName

        let config = parsed.config
        if let error = service.validateConfig(config) {
            errorMessage = error
            return
        }

        errorMessage = nil

        if let existing = editingServer {
            var updated = existing
            updated.name = finalName
            updated.serverConfig = config
            do {
                try service.updateServer(updated)
            } catch {
                errorMessage = "保存失败：\(error.localizedDescription)"
                return
            }
        } else {
            let server = McpServer(name: finalName, serverConfig: config, apps: [.codex])
            do {
                guard try service.addServer(server) == nil else { return }
            } catch {
                errorMessage = "添加失败：\(error.localizedDescription)"
                return
            }
        }
        isPresented = false
    }
}
