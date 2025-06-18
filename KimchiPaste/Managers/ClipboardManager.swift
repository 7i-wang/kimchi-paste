import SwiftUI
import AppKit
import UniformTypeIdentifiers

class ClipboardManager: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []
    // 修改：将 maxItems 从 private 改为 internal（默认访问级别）
    let maxItems = 10
    private var pasteboardChangeCount: Int = 0
    
    init() {
        loadSavedItems()
        startMonitoringPasteboard()
    }
    
    // 开始监听剪贴板变化
    private func startMonitoringPasteboard() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            while true {
                DispatchQueue.main.async {
                    self?.checkPasteboardChanges()
                }
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
    
    // 检查剪贴板是否有变化
    private func checkPasteboardChanges() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != pasteboardChangeCount {
            pasteboardChangeCount = currentChangeCount
            addCurrentPasteboardItem()
        }
    }
    
    // 添加当前剪贴板内容到管理列表
    private func addCurrentPasteboardItem() {
        let pasteboard = NSPasteboard.general
        
        // 尝试读取文本内容
        guard let string = pasteboard.string(forType: .string), !string.isEmpty else { return }
        
        // 检查是否已有相同内容
        if let existingIndex = clipboardItems.firstIndex(where: { $0.content == string }) {
            // 如果存在，将其移到顶部
            let existingItem = clipboardItems.remove(at: existingIndex)
            clipboardItems.insert(existingItem, at: 0)
        } else {
            // 否则添加新内容
            let newItem = ClipboardItem(content: string, timestamp: Date())
            clipboardItems.insert(newItem, at: 0)
            
            // 保持列表不超过最大数量
            if clipboardItems.count > maxItems {
                clipboardItems.removeLast()
            }
            
            // 保存到UserDefaults
            saveItems()
        }
    }
    
    // 复制内容到剪贴板
    func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(content, forType: .string)
    }
    
    // 删除指定项
    func removeItem(at offsets: IndexSet) {
        clipboardItems.remove(atOffsets: offsets)
        saveItems()
    }
    
    // 保存到UserDefaults
    internal func saveItems() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(clipboardItems) {
            UserDefaults.standard.set(encoded, forKey: "clipboardItems")
        }
    }
    
    // 从UserDefaults加载
    private func loadSavedItems() {
        if let savedItems = UserDefaults.standard.data(forKey: "clipboardItems") {
            let decoder = JSONDecoder()
            if let decodedItems = try? decoder.decode([ClipboardItem].self, from: savedItems) {
                clipboardItems = decodedItems
            }
        }
    }
}

// 剪贴板项模型
struct ClipboardItem: Identifiable, Equatable, Codable {
    var id = UUID()
    let content: String
    let timestamp: Date
    
    // 格式化时间显示
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    // 格式化日期和时间
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
