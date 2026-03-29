import SwiftUI

/// MCP 服务器添加/编辑表单
struct McpServerFormView: View {
    @Binding var isPresented: Bool
    @StateObject private var service = ClaudeMcpService.shared
    var editingServer: McpServer?

    @State private var name: String = ""
    @State private var configJson: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(editingServer != nil ? "编辑 MCP 服务器" : "添加 MCP 服务器")
                .font(.headline)

            Form {
                TextField("名称", text: $name)

                VStack(alignment: .leading, spacing: 4) {
                    Text("服务器配置 (JSON)")
                        .font(.system(size: 12))
                    TextEditor(text: $configJson)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                        )

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("取消") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button(editingServer != nil ? "保存" : "添加") {
                    saveServer()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || configJson.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: 450, height: 400)
        .onAppear {
            if let server = editingServer {
                name = server.name
                let dict = server.serverConfig.mapValues { $0.value }
                if let data = try? JSONSerialization.data(
                    withJSONObject: dict, options: .prettyPrinted),
                   let str = String(data: data, encoding: .utf8) {
                    configJson = str
                }
            } else {
                configJson = """
                {
                  "command": "npx",
                  "args": ["-y", "@modelcontextprotocol/server-example"]
                }
                """
            }
        }
    }

    private func saveServer() {
        guard let data = configJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            errorMessage = "无效的 JSON 格式"
            return
        }

        var config: [String: AnyCodable] = [:]
        for (key, value) in json {
            config[key] = AnyCodable(value)
        }

        if let error = service.validateConfig(config) {
            errorMessage = error
            return
        }

        errorMessage = nil

        if let existing = editingServer {
            var updated = existing
            updated.name = name
            updated.serverConfig = config
            service.updateServer(updated)
        } else {
            let server = McpServer(name: name, serverConfig: config)
            service.addServer(server)
        }
        isPresented = false
    }
}
