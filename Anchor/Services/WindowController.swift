import SwiftUI
import AppKit

final class WindowController: ObservableObject {
    static let shared = WindowController()

    private var mainWindow: NSWindow?

    func openMainWindow(appState: AppState) {
        NSApp.setActivationPolicy(.regular)

        if let mainWindow {
            mainWindow.orderFrontRegardless()
            mainWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let content = MainWindowView()
            .environmentObject(appState)
            .frame(minWidth: 960, minHeight: 680)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1040, height: 740),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Anchor"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(red: 0.008, green: 0.024, blue: 0.045, alpha: 1)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("AnchorMain")
        window.contentView = NSHostingView(rootView: content)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        mainWindow = window
    }
}
