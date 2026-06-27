import AppKit
import SwiftUI
import Combine

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var appState: AppState?
    private var cancellables = Set<AnyCancellable>()

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        configureButton()
    }

    func setup(appState: AppState) {
        self.appState = appState
        popover.contentViewController = NSHostingController(
            rootView: PopoverView()
                .environmentObject(appState)
                .frame(width: 360)
        )
        updateButton(active: appState.activeSession != nil)

        appState.$activeSession
            .receive(on: RunLoop.main)
            .sink { [weak self] session in
                self?.updateButton(active: session != nil)
                self?.refreshTimerDisplay()
            }
            .store(in: &cancellables)

        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshTimerDisplay()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshTimerDisplay()
            }
            .store(in: &cancellables)
    }

    func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        NSApp.activate(ignoringOtherApps: true)
    }

    func updateButton(active: Bool) {
        guard let button = statusItem.button else { return }
        button.image = AnchorIcon.menuBarImage(active: active)
        button.image?.isTemplate = true
        button.action = #selector(handleClick)
        button.target = self
        button.toolTip = active ? "Anchor — session active" : "Anchor"
        refreshTimerDisplay()
    }

    private func refreshTimerDisplay() {
        guard let button = statusItem.button else { return }
        let showTimer = UserDefaults.standard.bool(forKey: "showMenuBarTimer")

        guard showTimer,
              let session = appState?.activeSession,
              !session.isSnoozed else {
            button.title = ""
            return
        }

        let seconds = Int(session.timerDisplay)
        let m = seconds / 60
        let h = m / 60
        if h > 0 {
            button.title = " \(h):\(String(format: "%02d", m % 60))"
        } else {
            button.title = " \(m):\(String(format: "%02d", seconds % 60))"
        }
    }

    @objc private func handleClick() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.showMainWindow()
        }
        togglePopover()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = AnchorIcon.menuBarImage(active: false)
        button.image?.isTemplate = true
        button.action = #selector(handleClick)
        button.target = self
        button.toolTip = "Anchor"
    }
}

enum AnchorIcon {
    static func menuBarImage(active: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        let color = NSColor.labelColor
        color.setStroke()

        let path = NSBezierPath()
        path.lineWidth = 1.5
        path.lineCapStyle = .round

        path.move(to: NSPoint(x: 9, y: 3))
        path.line(to: NSPoint(x: 9, y: 12))

        path.move(to: NSPoint(x: 6, y: 12))
        path.line(to: NSPoint(x: 12, y: 12))

        path.move(to: NSPoint(x: 7.5, y: 5))
        path.curve(to: NSPoint(x: 9, y: 4), controlPoint1: NSPoint(x: 7.5, y: 4.2), controlPoint2: NSPoint(x: 8.2, y: 4))
        path.curve(to: NSPoint(x: 10.5, y: 5), controlPoint1: NSPoint(x: 9.8, y: 4), controlPoint2: NSPoint(x: 10.5, y: 4.2))

        path.move(to: NSPoint(x: 9, y: 14))
        path.line(to: NSPoint(x: 9, y: 15.5))

        path.stroke()

        if active {
            let dot = NSBezierPath(ovalIn: NSRect(x: 12, y: 2, width: 4, height: 4))
            NSColor.systemBlue.setFill()
            dot.fill()
        }

        image.unlockFocus()
        return image
    }
}
