import AppKit
import ApplicationServices

enum BrowserWindowTracker {
    static func frontWindowFrame(forBundleID bundleID: String) -> CGRect? {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
            return nil
        }
        if let axFrame = frontWindowFrame(forPID: app.processIdentifier) {
            return axFrame
        }
        return cgFrontWindowFrame(forPID: app.processIdentifier)
    }

    static func frontWindowFrame(forPID pid: pid_t) -> CGRect? {
        let app = AXUIElementCreateApplication(pid)
        var windowRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &windowRef) != .success {
            windowRef = nil
        }
        if windowRef == nil {
            var windowsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                  let windows = windowsRef as? [AXUIElement],
                  let first = windows.first else { return nil }
            windowRef = first
        }
        guard let windowRef else { return nil }
        guard CFGetTypeID(windowRef) == AXUIElementGetTypeID() else { return nil }
        return frame(of: windowRef as! AXUIElement)
    }

    private static func frame(of window: AXUIElement) -> CGRect? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let position = positionRef, let size = sizeRef else { return nil }

        var point = CGPoint.zero
        var cgSize = CGSize.zero
        guard AXValueGetValue(position as! AXValue, .cgPoint, &point),
              AXValueGetValue(size as! AXValue, .cgSize, &cgSize),
              cgSize.width > 80, cgSize.height > 80 else { return nil }

        return CGRect(origin: point, size: cgSize)
    }

    private static func cgFrontWindowFrame(forPID pid: pid_t) -> CGRect? {
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        for info in windows {
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t, ownerPID == pid else { continue }
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat] else { continue }

            let x = boundsDict["X"] ?? 0
            let y = boundsDict["Y"] ?? 0
            let w = boundsDict["Width"] ?? 0
            let h = boundsDict["Height"] ?? 0
            guard w > 80, h > 80 else { continue }

            let quartzFrame = CGRect(x: x, y: y, width: w, height: h)
            return appKitFrame(fromQuartz: quartzFrame)
        }
        return nil
    }

    private static func appKitFrame(fromQuartz quartz: CGRect) -> CGRect {
        for screen in NSScreen.screens {
            let f = screen.frame
            let windowTop = quartz.origin.y
            let windowBottom = windowTop + quartz.height
            let screenTopQuartz = f.maxY
            let screenBottomQuartz = f.minY
            if quartz.origin.x >= f.minX, quartz.origin.x < f.maxX,
               windowBottom > screenBottomQuartz, windowTop < screenTopQuartz {
                let y = f.maxY - windowTop - quartz.height
                return CGRect(x: quartz.origin.x, y: y, width: quartz.width, height: quartz.height)
            }
        }
        let main = NSScreen.main ?? NSScreen.screens[0]
        return CGRect(
            x: quartz.origin.x,
            y: main.frame.maxY - quartz.origin.y - quartz.height,
            width: quartz.width,
            height: quartz.height
        )
    }
}
