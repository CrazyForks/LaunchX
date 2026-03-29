import SwiftUI

/// Provider 预设选择器
struct ProviderPresetView: View {
    @Binding var isPresented: Bool
    @StateObject private var service = ClaudeProviderService.shared

    @State private var apiKey: String = ""
    @State private var selectedPreset: ClaudeProviderPreset?

    private let groupedPresets = ClaudeProviderPresetLoader.groupedPresets

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
                        ForEach(groupedPresets, id: \.category) { group in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.category.displayName)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.top, 8)

                                ForEach(group.presets) { preset in
                                    PresetRowView(
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
                        // 预设信息
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

                        // API Key 输入
                        VStack(alignment: .leading, spacing: 6) {
                            Text("API Key")
                                .font(.system(size: 12, weight: .medium))
                            SecureField("输入 API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                        }

                        // 配置预览
                        if !(preset.baseUrl?.isNullOrEmpty ?? true) || !(preset.model?.isNullOrEmpty ?? true) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("配置预览")
                                    .font(.system(size: 12, weight: .medium))
                                if let baseUrl = preset.baseUrl {
                                    HStack {
                                        Text("Base URL:")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                        Text(baseUrl)
                                            .font(.system(size: 11))
                                    }
                                }
                                if let model = preset.model {
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

                        // 按钮
                        HStack {
                            Spacer()
                            Button("取消") { isPresented = false }
                            Button("添加") {
                                if !apiKey.isEmpty {
                                    service.addProvider(from: preset, apiKey: apiKey)
                                    isPresented = false
                                }
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
    }
}

// MARK: - Preset Row

struct PresetRowView: View {
    let preset: ClaudeProviderPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: preset.icon ?? "server.rack")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: preset.iconColor ?? "#007AFF") ?? .accentColor)
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

// MARK: - String helper

extension String {
    var isNullOrEmpty: Bool { isEmpty }
}
