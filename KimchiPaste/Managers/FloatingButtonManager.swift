import SwiftUI
import AppKit
import Combine
import CoreGraphics

class FloatingButtonManager: ObservableObject {
    static let shared = FloatingButtonManager()

    @Published var isButtonVisible = true
    @Published var buttonPosition: CGPoint = .zero

    // 存储所有浮动按钮窗口
    private var floatingWindows: [NSWindow] = []
    private var subscriptions = Set<AnyCancellable>()
    private var screenCount = 0
    private var screenObserver: Any?

    // 用于预览的初始化器
    static func previewInstance() -> FloatingButtonManager {
        let instance = FloatingButtonManager()
        instance.isButtonVisible = true
        return instance
    }

    private init() {
        print("[FloatingButtonManager] 初始化")
        setupWindowObservation()
        positionButtonOnScreenEdge()

        // 初始创建按钮
        DispatchQueue.main.async {
            print("[FloatingButtonManager] 应用启动后创建浮动按钮")
            self.createFloatingButtons()
        }

        // 监听按钮可见性变化
        $isButtonVisible
            .sink { [weak self] visible in
                print("[FloatingButtonManager] 按钮可见性变更为: \(visible)")
                if visible {
                    self?.showAllFloatingButtons()
                } else {
                    self?.hideAllFloatingButtons()
                }
            }
            .store(in: &subscriptions)
    }

    deinit {
        print("[FloatingButtonManager] 销毁")
        hideAllFloatingButtons()

        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // 设置窗口观察
    private func setupWindowObservation() {
        print("[FloatingButtonManager] 设置窗口观察")

        // 使用正确的屏幕参数变化通知
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("[FloatingButtonManager] 检测到屏幕参数变化")
            self?.handleScreenChanges()
        }

        // 监听应用激活状态变化
        let appActivationSubscription = NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                print("[FloatingButtonManager] 应用激活状态变化")
                self?.updateFloatingButtons()
            }

        subscriptions.insert(appActivationSubscription)
    }

    // 处理屏幕变化
    private func handleScreenChanges() {
        let newScreenCount = NSScreen.screens.count

        if newScreenCount != screenCount {
            print("[FloatingButtonManager] 屏幕数量变化: 从 \(screenCount) 到 \(newScreenCount)")
            screenCount = newScreenCount
            createFloatingButtons()
        } else {
            print("[FloatingButtonManager] 屏幕配置变化，但数量未变")
            updateAllButtonPositions()
        }
    }

    // 更新浮动按钮
    private func updateFloatingButtons() {
        print("[FloatingButtonManager] 更新浮动按钮")
        guard isButtonVisible else {
            print("[FloatingButtonManager] 按钮不可见，跳过更新")
            return
        }

        // 如果按钮已经创建，只更新位置
        if !floatingWindows.isEmpty {
            print("[FloatingButtonManager] 更新所有按钮位置")
            updateAllButtonPositions()
            return
        }

        // 否则重新创建
        print("[FloatingButtonManager] 重新创建浮动按钮")
        createFloatingButtons()
    }

    // 创建浮动按钮（改进窗口配置）
    private func createFloatingButtons() {
        print("[FloatingButtonManager] 创建浮动按钮")
        // 清理现有按钮
        hideAllFloatingButtons()
        floatingWindows.removeAll()

        // 获取屏幕数量用于日志
        screenCount = NSScreen.screens.count
        print("[FloatingButtonManager] 检测到 \(screenCount) 个屏幕")

        // 为每个屏幕创建浮动按钮
        for (index, screen) in NSScreen.screens.enumerated() {
            print("[FloatingButtonManager] 为屏幕 \(index) 创建浮动按钮")

            // 计算按钮在当前屏幕上的位置
            let position = convertPositionToScreen(buttonPosition, screen: screen)
            let contentRect = NSRect(x: position.x, y: position.y, width: 40, height: 40)

            // 创建特殊的无边框窗口
            let window = NSWindow(
                contentRect: contentRect,
                styleMask: [.borderless, .nonactivatingPanel, .resizable],
                backing: .buffered,
                defer: false
            )

            // 使用更高的窗口级别确保可见性
            window.level = .statusBar
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
            window.alphaValue = isButtonVisible ? 1.0 : 0.0

            // 设置窗口内容视图
            let contentView = NSHostingView(
                rootView: FloatingButtonView()
                    .environmentObject(self)
                    .environmentObject(ClipboardManager())
            )

            window.contentView = contentView
            window.makeKeyAndOrderFront(nil)

            floatingWindows.append(window)
            print("[FloatingButtonManager] 屏幕 \(index) 浮动按钮创建成功，位置: \(position)")
        }

        print("[FloatingButtonManager] 共创建 \(floatingWindows.count) 个浮动按钮")
    }

    // 更新所有按钮位置
    private func updateAllButtonPositions() {
        print("[FloatingButtonManager] 更新所有按钮位置")
        for (index, screen) in NSScreen.screens.enumerated() {
            if index < floatingWindows.count {
                let position = convertPositionToScreen(buttonPosition, screen: screen)
                floatingWindows[index].setFrameOrigin(position)
                print("[FloatingButtonManager] 屏幕 \(index) 按钮位置更新为: \(position)")
            }
        }
    }

    // 转换坐标到指定屏幕（改进算法）
    private func convertPositionToScreen(_ position: CGPoint, screen: NSScreen) -> CGPoint {
        // 获取主屏幕作为参考
        guard let mainScreen = NSScreen.main else { return position }

        // 获取所有屏幕的帧，计算全局坐标系
        let allScreens = NSScreen.screens
        var minX: CGFloat = .infinity
        var minY: CGFloat = .infinity

        for s in allScreens {
            minX = min(minX, s.frame.minX)
            minY = min(minY, s.frame.minY)
        }

        // 计算相对位置
        let globalOrigin = CGPoint(x: minX, y: minY)

        // 计算相对于主屏幕的位置
        let relativeToMain = CGPoint(
            x: position.x - mainScreen.frame.minX + globalOrigin.x,
            y: position.y - mainScreen.frame.minY + globalOrigin.y
        )

        // 转换到目标屏幕
        return CGPoint(
            x: relativeToMain.x - screen.frame.minX,
            y: relativeToMain.y - screen.frame.minY
        )
    }

    // 显示所有浮动按钮
    func showAllFloatingButtons() {
        print("[FloatingButtonManager] 显示所有浮动按钮")
        floatingWindows.forEach { window in
            window.alphaValue = 1.0
            window.orderFront(nil)
        }
    }

    // 隐藏所有浮动按钮
    func hideAllFloatingButtons() {
        print("[FloatingButtonManager] 隐藏所有浮动按钮")
        floatingWindows.forEach { window in
            window.alphaValue = 0.0
            window.orderOut(nil)
        }
    }

    // 切换可见性
    func toggleVisibility() {
        isButtonVisible.toggle()
        print("[FloatingButtonManager] 切换可见性: \(isButtonVisible)")
    }

    // 设置初始位置
    private func positionButtonOnScreenEdge() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let padding: CGFloat = 20

        buttonPosition = CGPoint(
            x: screenFrame.maxX - 40 - padding,
            y: screenFrame.midY - 20
        )

        print("[FloatingButtonManager] 初始位置设置为: \(buttonPosition)")
    }
}
