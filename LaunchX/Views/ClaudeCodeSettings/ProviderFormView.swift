import SwiftUI

/// Provider 添加/编辑表单
struct ProviderFormView: View {
    @Binding var isPresented: Bool
    @StateObject private var service = ClaudeProviderService.shared
    var editingProvider: ClaudeProvider?

    @State private var name: String = ""
    @State private var apiKey: String = ""
    @State private var baseUrl: String = ""
    @State private var model: String = ""
    @State private var category: ClaudeProviderCategory = .thirdParty
    @State private var notes: String = ""

    var body: some View {
        VStack(spacing: 16) {
            // 标题
            Text(editingProvider != nil ? "编辑 Provider" : "添加 Provider")
                .font(.headline)

            Form {
                TextField("名称", text: $name)

                SecureField("API Key", text: $apiKey)
                    .help("ANTHROPIC_AUTH_TOKEN")

                TextField("Base URL", text: $baseUrl)
                    .help("ANTHROPIC_BASE_URL（可选）")

                TextField("模型", text: $model)
                    .help("ANTHROPIC_MODEL（可选）")

                Picker("分类", selection: $category) {
                    ForEach(ClaudeProviderCategory.allCases, id: \.self) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }

                TextField("备注", text: $notes)
            }
            .formStyle(.grouped)

            // 按钮
            HStack {
                Spacer()
                Button("取消") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button(editingProvider != nil ? "保存" : "添加") {
                    saveProvider()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: 400, height: 380)
        .onAppear {
            if let provider = editingProvider {
                name = provider.name
                apiKey = provider.apiKey ?? ""
                baseUrl = provider.baseUrl ?? ""
                model = provider.model ?? ""
                category = provider.category
                notes = provider.notes ?? ""
            }
        }
    }

    private func saveProvider() {
        var settingsConfig: [String: String] = [:]
        if !apiKey.isEmpty { settingsConfig["ANTHROPIC_AUTH_TOKEN"] = apiKey }
        if !baseUrl.isEmpty { settingsConfig["ANTHROPIC_BASE_URL"] = baseUrl }
        if !model.isEmpty { settingsConfig["ANTHROPIC_MODEL"] = model }

        if let existing = editingProvider {
            var updated = existing
            updated.name = name
            updated.settingsConfig = settingsConfig
            updated.category = category
            updated.notes = notes.isEmpty ? nil : notes
            service.updateProvider(updated)
        } else {
            let provider = ClaudeProvider(
                name: name,
                settingsConfig: settingsConfig,
                category: category,
                notes: notes.isEmpty ? nil : notes
            )
            service.addProvider(provider)
        }
        isPresented = false
    }
}
