import SwiftUI

struct RemindersSettingsView: View {
    @State private var settings = RemindersSettings.load()
    @State private var isAuthorized = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with icon, title, and toggle
                HStack(spacing: SettingsHeaderStyle.iconTitleSpacing) {
                    Image(systemName: AdvancedExtensionType.reminders.sfSymbolName)
                        .font(.system(size: SettingsHeaderStyle.iconSize))
                        .foregroundColor(AdvancedExtensionType.reminders.iconColor)
                        .frame(width: SettingsHeaderStyle.iconFrameSize, height: SettingsHeaderStyle.iconFrameSize)
                    Text("提醒事项")
                        .font(SettingsHeaderStyle.titleFont)
                        .fontWeight(SettingsHeaderStyle.titleFontWeight)
                    Spacer()

                    Toggle("", isOn: $settings.isEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: settings.isEnabled) { _, newValue in
                            settings.save()
                            if newValue && !isAuthorized {
                                requestAuthorization()
                            } else if !newValue {
                                // 关闭时清空搜索面板中的提醒事项
                                clearRemindersInSearchPanel()
                            }
                        }
                }
                .padding(.horizontal, SettingsHeaderStyle.horizontalPadding)
                .padding(.top, SettingsHeaderStyle.topPadding)
                .padding(.bottom, SettingsHeaderStyle.bottomPadding)

                Divider()

                // Authorization status and button
                if settings.isEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(isAuthorized ? .green : .orange)
                            Text(isAuthorized ? "已授权" : "未授权")
                                .font(.subheadline)
                            Spacer()
                        }

                        if !isAuthorized {
                            Button("授权") {
                                requestAuthorization()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        Text("提醒事项功能会从系统提醒事项 App 中获取今天和逾期的任务，并在搜索面板中显示。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                }

                Spacer()
            }
        }
        .onAppear {
            checkAuthorizationStatus()
        }
    }

    private func checkAuthorizationStatus() {
        isAuthorized = RemindersService.shared.checkAuthorization()
    }

    private func requestAuthorization() {
        RemindersService.shared.requestAccess { granted in
            isAuthorized = granted
        }
    }

    private func clearRemindersInSearchPanel() {
        NotificationCenter.default.post(name: Notification.Name("ClearRemindersNotification"), object: nil)
    }
}

#Preview {
    RemindersSettingsView()
        .frame(width: 600, height: 400)
}
