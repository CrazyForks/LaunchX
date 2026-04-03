import SwiftUI

/// MCP 服务器列表视图
struct McpServerListView: View {
    @StateObject private var service = ClaudeMcpService.shared
    @State private var showingAddSheet = false
    @State private var editingServer: McpServer?
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                Text("MCP")
                    .font(.headline)
                Spacer()
                Button(action: {
                    let count = service.importFromClaude()
                    if count > 0 {
                        // 成功导入
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                        Text("从 Claude 导入")
                    }
                    .font(.system(size: 12))
                }
                Button(action: { showingAddSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("添加")
                    }
                    .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            if service.servers.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("暂无 MCP")
                        .foregroundColor(.secondary)
                    Text("点击「添加」创建新的 MCP，或「从 Claude 导入」已有配置")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(service.servers) { server in
                            McpServerRowView(
                                server: server,
                                onToggle: {
                                    do {
                                        try service.toggleEnabled(server)
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showError = true
                                    }
                                },
                                onEdit: { editingServer = server },
                                onDelete: {
                                    do {
                                        try service.deleteServer(server)
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showError = true
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
        .sheet(isPresented: $showingAddSheet) {
            McpServerFormView(isPresented: $showingAddSheet)
        }
        .sheet(item: $editingServer) { server in
            McpServerFormView(
                isPresented: Binding(
                    get: { editingServer != nil },
                    set: { if !$0 { editingServer = nil } }
                ),
                editingServer: server
            )
        }
    }
}

// MARK: - MCP Server Row

struct McpServerRowView: View {
    let server: McpServer
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            // 类型图标
            Image(systemName: server.serverType == .stdio ? "terminal" : "globe")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)
            // 信息
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(server.name)
                        .font(.system(size: 13, weight: .medium))
                    Text(server.serverType.displayName)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(3)
                }
                Text(server.configSummary)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
            // 操作按钮 - 直接展示
            Button(action: onToggle) {
                Image(systemName: server.isEnabled ? "pause.circle" : "play.circle")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundColor(server.isEnabled ? .orange : .green)
            .help(server.isEnabled ? "禁用" : "启用")

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .help("编辑")

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundColor(.red.opacity(0.7))
            .help("删除")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(server.isEnabled ? Color.accentColor.opacity(0.05) : Color.clear)
        .cornerRadius(6)
    }
}
