import SwiftUI

struct SettingsView: View {
    @AppStorage("isLaunchAgentEnabled") private var isLaunchAgentEnabled = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    let launchAgentManager = LaunchAgentManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("开机自启动")
                .font(.headline)

            Toggle("开机时自动启动应用", isOn: $isLaunchAgentEnabled)
                .onChange(of: isLaunchAgentEnabled) { enabled in
                    updateLaunchAgent(enabled: enabled)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .disabled(isProcessing)

            if let error = errorMessage {
                Text("错误: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .onAppear {
            // 检查 LaunchAgent 是否已安装
            isLaunchAgentEnabled = launchAgentManager.isLaunchAgentInstalled()
        }
    }

    private func updateLaunchAgent(enabled: Bool) {
        isProcessing = true
        errorMessage = nil

        DispatchQueue.global().async {
            do {
                if enabled {
                    try launchAgentManager.installLaunchAgent()
                } else {
                    try launchAgentManager.uninstallLaunchAgent()
                }

                DispatchQueue.main.async {
                    isProcessing = false
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    // 恢复开关状态
                    isLaunchAgentEnabled = !enabled
                }
            }
        }
    }
}
