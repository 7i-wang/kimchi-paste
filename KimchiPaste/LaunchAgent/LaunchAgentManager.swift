import Foundation

class LaunchAgentManager {
    // LaunchAgent 配置文件的目标路径（用户 LaunchAgents 目录）
    private let destinationPlistURL: URL
    // 应用当前路径
    private let applicationPath: String
    // 应用标识符
    private let appIdentifier: String

    init(appIdentifier: String = "com.ench.KimchiPaste") {
        self.appIdentifier = appIdentifier

        // 获取应用包路径
        let appPath = Bundle.main.bundleURL.path

        self.applicationPath = appPath

        // 获取用户 LaunchAgents 目录路径（修正为 ~/Library/LaunchAgents/）
        let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let launchAgentsDir = libraryDir.appendingPathComponent("LaunchAgents", isDirectory: true)
        self.destinationPlistURL = launchAgentsDir.appendingPathComponent("\(appIdentifier).plist")
    }

    // 安装 LaunchAgent
    func installLaunchAgent() throws {
        try createLaunchAgentsDirectoryIfNeeded()

        // 从模板生成配置文件
        let plistContent = try generatePlistContent()
        try plistContent.write(to: destinationPlistURL, atomically: true, encoding: .utf8)

        // 设置适当的文件权限
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: destinationPlistURL.path)

        // 加载 LaunchAgent
        try loadLaunchAgent()
    }

    // 卸载 LaunchAgent
    func uninstallLaunchAgent() throws {
        // 卸载 LaunchAgent
        try unloadLaunchAgent()

        // 删除配置文件
        if FileManager.default.fileExists(atPath: destinationPlistURL.path) {
            try FileManager.default.removeItem(at: destinationPlistURL)
        }
    }

    // 检查 LaunchAgent 是否已安装且配置正确
    func isLaunchAgentInstalledAndValid() -> Bool {
        guard FileManager.default.fileExists(atPath: destinationPlistURL.path) else {
            return false
        }

        do {
            // 读取现有配置
            let plistData = try Data(contentsOf: destinationPlistURL)
            let plistDict = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]

            // 验证 ProgramArguments 中的路径
            guard let programArgs = plistDict?["ProgramArguments"] as? [String],
                  programArgs.count > 0,
                  programArgs[0].contains(applicationPath) else {
                return false
            }

            return true
        } catch {
            print("检查 LaunchAgent 配置失败: \(error)")
            return false
        }
    }

    // 从模板生成 LaunchAgent 配置内容
    private func generatePlistContent() throws -> String {
        // 模板内容（使用 APP_PATH 占位符）
        let template = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>\(appIdentifier)</string>
                <key>ProgramArguments</key>
                <array>
                    <string>APP_PATH/Contents/MacOS/KimchiPaste</string>
                    <string>--launchagent</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>KeepAlive</key>
                <true/>
                <key>StandardOutPath</key>
                <string>/tmp/\(appIdentifier).stdout</string>
                <key>StandardErrorPath</key>
                <string>/tmp/\(appIdentifier).stderr</string>
            </dict>
            </plist>
            """

        // 替换占位符为实际路径
        return template.replacingOccurrences(of: "APP_PATH", with: applicationPath)
    }

    // 确保 LaunchAgents 目录存在
    private func createLaunchAgentsDirectoryIfNeeded() throws {
        let launchAgentsDir = destinationPlistURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: launchAgentsDir.path) {
            try FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
        }
    }

    // 加载 LaunchAgent
    private func loadLaunchAgent() throws {
        try runLaunchctlCommand(["load", "-w", destinationPlistURL.path])
    }

    // 卸载 LaunchAgent
    private func unloadLaunchAgent() throws {
        try runLaunchctlCommand(["unload", "-w", destinationPlistURL.path])
    }

    // 执行 launchctl 命令
    private func runLaunchctlCommand(_ arguments: [String]) throws {
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "LaunchAgentError", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "执行 launchctl 命令失败: \(output)"])
        }
    }
}
