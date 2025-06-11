import SwiftUI

@main
struct KimchiPasteApp: App {
    // 创建并初始化 ClipboardManager 实例
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some Scene {
        WindowGroup {
            // 将 ClipboardManager 实例通过 environmentObject 传递给 ContentView
            ContentView()
                .environmentObject(clipboardManager)
                .frame(minWidth: 260, maxWidth: 400, minHeight: 340, maxHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}
