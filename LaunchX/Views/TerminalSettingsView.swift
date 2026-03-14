import SwiftUI

struct TerminalSettingsView: View {
    @State private var settings = TerminalSettings.load()
    private let labelWidth: CGFloat = 160

    // 过滤出系统中已安装的终端，或者始终保留系统自带终端作为兜底
    private var availableTerminals: [TerminalType] {
        TerminalType.allCases.filter { $0.isInstalled || $0 == .appleTerminal }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 标题行
                HStack {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    Text("终端设置")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                Divider()

                // 终端选择
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 0) {
                        Text("默认终端工具:")
                            .frame(width: labelWidth, alignment: .leading)

                        VStack(alignment: .leading, spacing: 8) {
                            Picker("", selection: $settings.selectedTerminal) {
                                ForEach(availableTerminals) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .labelsHidden()
                            .frame(minWidth: 150, alignment: .leading)
                            .onChange(of: settings.selectedTerminal) { _, _ in
                                settings.save()
                            }

                            Text("选择 \"cd 至此\" 功能默认使用的终端应用。仅显示当前系统中已安装的终端。")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
                .padding(20)

                Spacer()
            }
        }
    }
}

#Preview {
    TerminalSettingsView()
}
