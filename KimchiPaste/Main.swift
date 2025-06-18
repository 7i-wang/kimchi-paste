import SwiftUI
import AppKit

@main
struct KimchiPasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 为所有现有窗口创建浮动按钮
            FloatingButtonManager.shared.showAllFloatingButtons()

            // 隐藏默认主窗口
            if let window = NSApp.windows.first {
                window.setFrame(CGRect(x: 0, y: 0, width: 1, height: 1), display: false)
                window.level = .statusBar
                window.orderOut(nil)
            }
        }
    }
}
