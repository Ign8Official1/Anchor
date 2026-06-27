import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var statusBarController: StatusBarController?
    private var sessionObserver: AnyCancellable?
    private var escapeMonitor: Any?

    func applicationWillFinishLaunching(_ notification: Notification) {
        OceanPrewarmer.shared.start()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let icon = BrandMark.image {
            NSApp.applicationIconImage = icon
        }
        NSApp.setActivationPolicy(.regular)

        let statusBar = StatusBarController()
        statusBar.setup(appState: appState)
        statusBarController = statusBar

        sessionObserver = appState.$activeSession
            .receive(on: RunLoop.main)
            .sink { [weak self] session in
                self?.statusBarController?.updateButton(active: session != nil)
            }

        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard LockScreenController.shared.isVisible, event.keyCode == 53 else { return event }
            self?.appState.dismissBlockOverlay(userInitiated: true)
            return nil
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.showMainWindow()
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let session = appState.activeSession, session.protection.preventsAppQuit {
            NSSound.beep()
            return .terminateCancel
        }
        BlockPageServer.shared.stop()
        return .terminateNow
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        WindowController.shared.openMainWindow(appState: appState)
        NSApp.activate(ignoringOtherApps: true)
    }
}
