import SwiftUI

/// Codex Provider 编辑表单
struct CodexProviderFormView: View {
    @Binding var isPresented: Bool
    @State var editingProvider: CodexProvider?

    @State private var name: String = ""
    @State private var providerId: String = ""
    @State private var baseUrl: String = ""
    @State private var envKey: String = "OPENAI_API_KEY"
    @State private var apiKey: String = ""
    @State private var wireApi: String = "responses"
    @State private var model: String = ""
    @State private var category: CodexProviderCategory = .thirdParty
    @State private var notes: String = ""

    private let service = CodexProviderService.shared

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            Text(editingProvider == nil ? "添加 Provider" : "编辑 Provider")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    formRow("名称") {
                        TextField("显示名称", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    formRow("Provider ID") {
                        TextField("如 openai, mistral", text: $providerId)
                            .textFieldStyle(.roundedBorder)
                    }
                    formRow("Base URL") {
                        TextField("https://api.openai.com/v1", text: $baseUrl)
                            .textFieldStyle(.roundedBorder)
                    }
                    formRow("API Key 变量名") {
                        TextField("OPENAI_API_KEY", text: $envKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    formRow("API Key") {
                        SecureField("sk-...", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    formRow("Wire API") {
                        Picker("", selection: $wireApi) {
                            Text("responses").tag("responses")
                            Text("chat_completions").tag("chat_completions")
                        }
                        .pickerStyle(.segmented)
                    }
                    formRow("默认模型") {
                        TextField("o4-mini", text: $model)
                            .textFieldStyle(.roundedBorder)
                    }
                    formRow("分类") {
                        Picker("", selection: $category) {
                            ForEach(CodexProviderCategory.allCases, id: \.self) { cat in
                                Text(cat.displayName).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    formRow("备注") {
                        TextField("可选", text: $notes)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(16)
            }

            Divider()

            // 按钮
            HStack {
                Spacer()
                Button("取消") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button("保存") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty || providerId.isEmpty)
            }
            .padding(16)
        }
        .frame(width: 420, height: 460)
        .onAppear {
            if let p = editingProvider {
                name = p.name
                providerId = p.providerId
                baseUrl = p.baseUrl
                envKey = p.envKey
                apiKey = p.apiKey
                wireApi = p.wireApi ?? "responses"
                model = p.model ?? ""
                category = p.category
                notes = p.notes ?? ""
            }
        }
    }

    private func formRow(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        HStack {
            Text(label)
                .frame(width: 100, alignment: .trailing)
            content()
        }
    }

    private func save() {
        if let existing = editingProvider {
            var updated = existing
            updated.name = name
            updated.providerId = providerId
            updated.baseUrl = baseUrl
            updated.envKey = envKey
            updated.apiKey = apiKey
            updated.wireApi = wireApi.isEmpty ? nil : wireApi
            updated.model = model.isEmpty ? nil : model
            updated.category = category
            updated.notes = notes.isEmpty ? nil : notes
            try? service.updateProvider(updated)
        } else {
            let provider = CodexProvider(
                name: name,
                providerId: providerId,
                baseUrl: baseUrl,
                envKey: envKey,
                apiKey: apiKey,
                wireApi: wireApi.isEmpty ? nil : wireApi,
                model: model.isEmpty ? nil : model,
                category: category,
                notes: notes.isEmpty ? nil : notes
            )
            try? service.addProvider(provider)
        }
        isPresented = false
    }
}
