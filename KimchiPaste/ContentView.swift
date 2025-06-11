import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var showAlert = false
    @State private var copiedItem: String?
    @State private var searchText = ""
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.clipboardItems
        } else {
            return clipboardManager.clipboardItems.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .padding(.leading, 12)
                
                TextField("搜索剪贴板内容...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 8)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 8)
                }
            }
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            .padding(8)
            
            List {
                if filteredItems.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("剪贴板历史记录为空")
                            .font(.headline)
                        
                        Text("复制一些文本后，它们会显示在这里")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 36)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardItemView(item: item, onCopy: { content in
                            clipboardManager.copyToClipboard(content)
                            copiedItem = content
                            showAlert = true
                        })
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                // 获取当前项的ID
                                let itemId = filteredItems[index].id
                                // 找到实际数据中的索引
                                if let realIndex = clipboardManager.clipboardItems.firstIndex(where: { $0.id == itemId }) {
                                    clipboardManager.removeItem(at: IndexSet(integer: realIndex))
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }.tint(Color(red: 1.0, green: 0.38823529411764707, blue: 0.38823529411764707))
                        }
                    }
                    .onDelete(perform: { offsets in
                        let indicesToRemove = offsets.map { filteredItems[$0].id }
                        let realIndices = clipboardManager.clipboardItems.indices(where: { indicesToRemove.contains($0.id) })
                        clipboardManager.removeItem(at: realIndices)
                    })
                }
            }
            .listStyle(PlainListStyle())
            
            // 状态栏
            HStack {
                Text("\(clipboardManager.clipboardItems.count)/\(clipboardManager.maxItems) 项")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.9333333333333333, green: 0.9372549019607843, blue: 0.8784313725490196))
                    .padding(.leading, 16)
                
                Spacer()
                
                Button(action: {
                    clipboardManager.clipboardItems.removeAll()
                    clipboardManager.saveItems()
                }) {
                    Text("清空所有")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.9333333333333333, green: 0.9372549019607843, blue: 0.8784313725490196))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 16)
            }
            .frame(height: 32)
            .background(Color(red: 0.6549019607843137, green: 0.7568627450980392, blue: 0.6588235294117647))
            .border(Color(.separatorColor), width: 0.5)
        }
        .background(Color(red: 0.6549019607843137, green: 0.7568627450980392, blue: 0.6588235294117647))
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("已复制"),
                message: Text("内容已复制到剪贴板"),
                dismissButton: .default(Text("确定"))
            )
        }
    }
}

// 单个剪贴板项的视图
struct ClipboardItemView: View {
    let item: ClipboardItem
    let onCopy: (String) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .font(.body)
                    .lineLimit(2)
                
                Text(item.formattedDateTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                onCopy(item.content)
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(Color(red: 0.5058823529411764, green: 0.6039215686274509, blue: 0.5686274509803921))
                    .padding(8)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor))
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
}

// 扩展 Array 以获取符合条件的索引集合
extension Array where Element: Identifiable {
    func indices(where predicate: (Element) -> Bool) -> IndexSet {
        var indices = IndexSet()
        for (index, element) in self.enumerated() {
            if predicate(element) {
                indices.insert(index)
            }
        }
        return indices
    }
}

// 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ClipboardManager())
    }
}
