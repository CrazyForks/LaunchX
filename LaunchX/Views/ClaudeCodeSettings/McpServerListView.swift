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
                Text("MCP 服务器")
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
                    Text("暂无 MCP 服务器")
                        .foregroundColor(.secondary)
                    Text("点击「添加」创建新的 MCP 服务器，或「从 Claude 导入」已有配置")
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
                                onToggle: { service.toggleEnabled(server) },
                                onEdit: { editingServer = server },
                                onDelete: { service.deleteServer(server) }
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
            // 启用开关
            Toggle("", isOn: Binding(
                get: { server.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()

            // 类型图标
            Image(systemName: server.serverType == .stdio ? "terminal" : "globe")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)

            // 信息
            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.system(size: 13, weight: .medium))
                Text(server.configSummary)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // 类型标签
            Text(server.serverType.displayName)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)

            // 菜单
            Menu {
                Button(action: onEdit) {
                    Label("编辑", systemImage: "pencil")
                }
                Divider()
                Button(role: .destructive, action: onDelete) {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(server.isEnabled ? Color.accentColor.opacity(0.05) : Color.clear)
        .cornerRadius(6)
    }
}
