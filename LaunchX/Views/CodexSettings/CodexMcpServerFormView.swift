import SwiftUI

/// Codex MCP Server 编辑表单
struct CodexMcpServerFormView: View {
    @Binding var isPresented: Bool
    @State var editingServer: CodexMcpServer?

    @State private var name: String = ""
    @State private var serverType: CodexMcpServerType = .stdio
    @State private var command: String = ""
    @State private var args: String = ""
    @State private var url: String = ""
    @State private var bearerTokenEnvVar: String = ""
    @State private var startupTimeout: String = ""
    @State private var toolTimeout: String = ""

    private let service = CodexMcpService.shared

    var body: some View {
        VStack(spacing: 0) {
            Text(editingServer == nil ? "添加 MCP Server" : "编辑 MCP Server")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    formRow("名称") {
                        TextField("服务器名称", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    formRow("类型") {
                        Picker("", selection: $serverType) {
                            ForEach(CodexMcpServerType.allCases, id: \.self) { t in
                                Text(t.displayName).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if serverType == .stdio {
                        formRow("Command") {
                            TextField("npx", text: $command)
                                .textFieldStyle(.roundedBorder)
                        }
                        formRow("Args") {
                            TextField("参数，空格分隔", text: $args)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else {
                        formRow("URL") {
                            TextField("https://example.com/mcp", text: $url)
                                .textFieldStyle(.roundedBorder)
                        }
                        formRow("Bearer Token 变量") {
                            TextField("MY_MCP_TOKEN", text: $bearerTokenEnvVar)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    formRow("启动超时(秒)") {
                        TextField("10", text: $startupTimeout)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    formRow("工具超时(秒)") {
                        TextField("60", text: $toolTimeout)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
                .padding(16)
            }

            Divider()

            HStack {
                Spacer()
                Button("取消") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button("保存") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty)
            }
            .padding(16)
        }
        .frame(width: 420, height: 420)
        .onAppear {
            if let s = editingServer {
                name = s.name
                serverType = s.serverType
                command = s.command ?? ""
                args = (s.args ?? []).joined(separator: " ")
                url = s.url ?? ""
                bearerTokenEnvVar = s.bearerTokenEnvVar ?? ""
                startupTimeout = s.startupTimeoutSec.map { "\($0)" } ?? ""
                toolTimeout = s.toolTimeoutSec.map { "\($0)" } ?? ""
            }
        }
    }

    private func formRow(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .trailing)
            content()
        }
    }

    private func save() {
        let argsArray = args.split(separator: " ").map(String.init)
        let server = CodexMcpServer(
            name: name,
            serverType: serverType,
            command: serverType == .stdio ? command : nil,
            args: serverType == .stdio && !argsArray.isEmpty ? argsArray : nil,
            url: serverType == .streamableHttp ? url : nil,
            startupTimeoutSec: Int(startupTimeout),
            toolTimeoutSec: Int(toolTimeout),
            bearerTokenEnvVar: serverType == .streamableHttp && !bearerTokenEnvVar.isEmpty ? bearerTokenEnvVar : nil
        )

        if let existing = editingServer {
            var updated = server
            updated.id = existing.id
            updated.isEnabled = existing.isEnabled
            try? service.updateServer(updated)
        } else {
            if let error = service.addServer(server) {
                // 验证失败
                _ = error
            }
        }
        isPresented = false
    }
}
