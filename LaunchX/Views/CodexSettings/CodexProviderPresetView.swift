import SwiftUI

/// Codex Provider 预设选择器
struct CodexProviderPresetView: View {
    @Binding var isPresented: Bool
    @State private var selectedPreset: CodexProviderPreset?
    @State private var apiKey: String = ""
    @State private var showError = false
    @State private var errorMessage = ""

    private let presets = CodexProviderPresetLoader.groupedPresets
    private let service = CodexProviderService.shared

    var body: some View {
        VStack(spacing: 0) {
            Text("从预设添加 Provider")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 8)

            HSplitView {
                // 预设列表
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(presets, id: \.category) { group in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.category.displayName)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.top, 8)

                                ForEach(group.presets) { preset in
                                    CodexPresetRowView(
                                        preset: preset,
                                        isSelected: selectedPreset?.id == preset.id
                                    ) {
                                        selectedPreset = preset
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(minWidth: 200, maxWidth: 240)

                // 右侧配置区
                if let preset = selectedPreset {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name)
                                .font(.system(size: 14, weight: .semibold))
                            if let desc = preset.presetDescription {
                                Text(desc)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            if let website = preset.websiteUrl {
                                Link(destination: URL(string: website)!) {
                                    Text(website)
                                        .font(.system(size: 11))
                                        .foregroundColor(.accentColor)
                                        .lineLimit(1)
                                }
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("API Key")
                                .font(.system(size: 12, weight: .medium))
                            SecureField("输入 API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                        }

                        if !(preset.baseUrl?.isEmpty ?? true) || !(preset.model?.isEmpty ?? true) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("配置预览")
                                    .font(.system(size: 12, weight: .medium))
                                if let baseUrl = preset.baseUrl, !baseUrl.isEmpty {
                                    HStack {
                                        Text("Base URL:")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                        Text(baseUrl)
                                            .font(.system(size: 11))
                                    }
                                }
                                if let model = preset.model, !model.isEmpty {
                                    HStack {
                                        Text("Model:")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                        Text(model)
                                            .font(.system(size: 11))
                                    }
                                }
                            }
                        }

                        Spacer()

                        HStack {
                            Spacer()
                            Button("取消") {
                                isPresented = false
                            }
                            Button("添加") {
                                addFromPreset()
                            }
                            .keyboardShortcut(.defaultAction)
                            .disabled(apiKey.isEmpty)
                        }
                    }
                    .padding(16)
                    .frame(minWidth: 240)
                } else {
                    VStack {
                        Spacer()
                        Text("选择一个预设")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(minWidth: 240)
                }
            }
        }
        .frame(width: 560, height: 420)
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func addFromPreset() {
        guard let preset = selectedPreset else { return }
        do {
            try service.addProvider(from: preset, apiKey: apiKey)
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preset Row

struct CodexPresetRowView: View {
    let preset: CodexProviderPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: preset.icon ?? "server.rack")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: preset.iconColor ?? "#FF9500") ?? .orange)
                    .frame(width: 20)
                Text(preset.name)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}
