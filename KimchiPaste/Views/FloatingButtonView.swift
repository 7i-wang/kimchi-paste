import SwiftUI
import AppKit

struct FloatingButtonView: View {
    @EnvironmentObject var floatingButtonManager: FloatingButtonManager
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var isShowingPopover = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.6078431372549019, green: 0.8313725490196079, blue: 0.8941176470588236))
                .frame(width: 40, height: 40)
                .shadow(radius: 5)
                .cornerRadius(8)
        }
        .onTapGesture {
            isShowingPopover = true
        }
        .popover(isPresented: $isShowingPopover) {
            ContentView()
                .environmentObject(clipboardManager)
                .frame(minWidth: 260, maxWidth: 400, minHeight: 340, maxHeight: 500)
        }
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// 预览
struct FloatingButtonView_Previews: PreviewProvider {
    static var previews: some View {
        FloatingButtonView()
            .environmentObject(FloatingButtonManager.previewInstance())
    }
}
