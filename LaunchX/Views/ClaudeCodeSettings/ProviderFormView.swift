import SwiftUI

/// Provider 添加/编辑表单
struct ProviderFormView: View {
    @Binding var isPresented: Bool
    @StateObject private var service = ClaudeProviderService.shared
    var editingProvider: ClaudeProvider?

    // MARK: - 表单状态

    @State private var name: String = ""
    @State private var apiKey: String = ""
    @State private var showApiKey: Bool = false
    @State private var baseUrl: String = ""
    @State private var defaultModel: String = ""
    @State private var reasoningModel: String = ""
    @State private var haikuModel: String = ""
    @State private var sonnetModel: String = ""
    @State private var opusModel: String = ""
    @State private var category: ClaudeProviderCategory = .thirdParty

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar

            Divider()

            // 表单内容
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    basicInfoSection
                    Divider()
                    apiConfigSection
                    Divider()
                    modelConfigSection
                    Divider()
                    envPreviewSection
                }
                .padding(20)
            }

            Divider()

            actionBar
        }
        .frame(width: 520, height: 580)
        .onAppear {
            if let provider = editingProvider {
                name = provider.name
                apiKey = provider.apiKey ?? ""
                baseUrl = provider.baseUrl ?? ""
                category = provider.category
                defaultModel = provider.settingsConfig["ANTHROPIC_MODEL"] ?? ""
                reasoningModel = provider.settingsConfig["ANTHROPIC_REASONING_MODEL"] ?? ""
                haikuModel = provider.settingsConfig["ANTHROPIC_DEFAULT_HAIKU_MODEL"] ?? ""
                sonnetModel = provider.settingsConfig["ANTHROPIC_DEFAULT_SONNET_MODEL"] ?? ""
                opusModel = provider.settingsConfig["ANTHROPIC_DEFAULT_OPUS_MODEL"] ?? ""
            }
        }
    }

    // MARK: - 标题栏

    private var titleBar: some View {
        HStack {
            if let provider = editingProvider {
                Image(systemName: provider.category.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: provider.iconColor ?? "#007AFF") ?? .accentColor)
            }
            Text(editingProvider != nil ? "编辑 Provider" : "添加 Provider")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - 基本信息

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("基本信息", icon: "info.circle")

            // 名称
            HStack(spacing: 12) {
                Text("名称")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 90, alignment: .trailing)
                    .padding(.top, 4)
                TextField("例如：OpenRouter", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }

            // 分类
            HStack(alignment: .top, spacing: 12) {
                Text("分类")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 90, alignment: .trailing)
                    .padding(.top, 4)
                Picker("", selection: $category) {
                    ForEach(ClaudeProviderCategory.allCases, id: \.self) { cat in
                        HStack(spacing: 6) {
                            Image(systemName: cat.iconName)
                                .font(.system(size: 11))
                            Text(cat.displayName)
                        }
                        .tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - API 配置

    private var apiConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("API 配置", icon: "key.fill")

            // API Key
            HStack(spacing: 12) {
                Text("API Key")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 90, alignment: .trailing)
                    .padding(.top, 4)

                HStack {
                    if showApiKey {
                        TextField("输入 API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    } else {
                        SecureField("输入 API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    Button(action: { showApiKey.toggle() }) {
                        Image(systemName: showApiKey ? "eye.slash" : "eye")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 24)
                }
            }

            // Base URL
            HStack(spacing: 12) {
                Text("Base URL")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 90, alignment: .trailing)
                    .padding(.top, 4)
                TextField("https://api.example.com/v1", text: $baseUrl)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
            }
        }
    }

    // MARK: - 模型配置

    private var modelConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("模型配置", icon: "cpu")

            simpleModelField("Default", placeholder: "claude-sonnet-4-20250514", text: $defaultModel)
            simpleModelField("Reasoning", placeholder: "claude-sonnet-4-20250514", text: $reasoningModel)
            simpleModelField("Haiku", placeholder: "claude-haiku-4-20250514", text: $haikuModel)
            simpleModelField("Sonnet", placeholder: "claude-sonnet-4-20250514", text: $sonnetModel)
            simpleModelField("Opus", placeholder: "claude-opus-4-20250514", text: $opusModel)
        }
    }

    // MARK: - 环境变量预览（始终展示）

    private var envPreviewSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("环境变量预览", icon: "terminal")

            VStack(alignment: .leading, spacing: 4) {
                envRow("ANTHROPIC_AUTH_TOKEN", value: apiKey.isEmpty ? "（未设置）" : maskApiKey(apiKey), isSet: !apiKey.isEmpty)
                envRow("ANTHROPIC_BASE_URL", value: baseUrl.isEmpty ? "（未设置）" : baseUrl, isSet: !baseUrl.isEmpty)
                envRow("ANTHROPIC_MODEL", value: defaultModel.isEmpty ? "（未设置）" : defaultModel, isSet: !defaultModel.isEmpty)
                envRow("ANTHROPIC_REASONING_MODEL", value: reasoningModel.isEmpty ? "（未设置）" : reasoningModel, isSet: !reasoningModel.isEmpty)
                envRow("ANTHROPIC_DEFAULT_HAIKU_MODEL", value: haikuModel.isEmpty ? "（未设置）" : haikuModel, isSet: !haikuModel.isEmpty)
                envRow("ANTHROPIC_DEFAULT_SONNET_MODEL", value: sonnetModel.isEmpty ? "（未设置）" : sonnetModel, isSet: !sonnetModel.isEmpty)
                envRow("ANTHROPIC_DEFAULT_OPUS_MODEL", value: opusModel.isEmpty ? "（未设置）" : opusModel, isSet: !opusModel.isEmpty)
            }
            .padding(10)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
        }
    }

    // MARK: - 底部操作栏

    private var actionBar: some View {
        HStack {
            Spacer()
            Button("取消") { isPresented = false }
                .keyboardShortcut(.cancelAction)
            Button(editingProvider != nil ? "保存" : "添加") {
                saveProvider()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(name.isEmpty || apiKey.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - 辅助组件

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.accentColor)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
        }
    }

    private func simpleModelField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 90, alignment: .trailing)
                .padding(.top, 4)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))
        }
    }

    private func envRow(_ key: String, value: String, isSet: Bool) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isSet ? Color.green : Color.orange.opacity(0.6))
                .frame(width: 5, height: 5)
            Text(key)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
            Text("=")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(isSet ? .primary : .secondary)
                .lineLimit(1)
        }
    }

    private func maskApiKey(_ key: String) -> String {
        if key.count <= 8 {
            return String(repeating: "•", count: key.count)
        }
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(4))
        return "\(prefix)••••\(suffix)"
    }

    // MARK: - 保存

    private func saveProvider() {
        var settingsConfig: [String: String] = [:]
        if !apiKey.isEmpty { settingsConfig["ANTHROPIC_AUTH_TOKEN"] = apiKey }
        if !baseUrl.isEmpty { settingsConfig["ANTHROPIC_BASE_URL"] = baseUrl }
        if !defaultModel.isEmpty { settingsConfig["ANTHROPIC_MODEL"] = defaultModel }
        if !reasoningModel.isEmpty { settingsConfig["ANTHROPIC_REASONING_MODEL"] = reasoningModel }
        if !haikuModel.isEmpty { settingsConfig["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = haikuModel }
        if !sonnetModel.isEmpty { settingsConfig["ANTHROPIC_DEFAULT_SONNET_MODEL"] = sonnetModel }
        if !opusModel.isEmpty { settingsConfig["ANTHROPIC_DEFAULT_OPUS_MODEL"] = opusModel }

        if let existing = editingProvider {
            var updated = existing
            updated.name = name
            updated.settingsConfig = settingsConfig
            updated.category = category
            service.updateProvider(updated)
        } else {
            let provider = ClaudeProvider(
                name: name,
                settingsConfig: settingsConfig,
                category: category
            )
            service.addProvider(provider)
        }
        isPresented = false
    }
}
