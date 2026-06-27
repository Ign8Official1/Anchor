import AppKit
import ApplicationServices

enum PermissionChecker {
    struct Status {
        var hasAccessibility: Bool
        var hasSystemEventsAutomation: Bool
        var browserAutomation: [String: Bool]

        var isReadyForSiteBlocking: Bool {
            hasAccessibility && (hasSystemEventsAutomation || browserAutomation.values.contains(true))
        }

        var missingItems: [String] {
            var items: [String] = []
            if !hasAccessibility { items.append("Accessibility") }
            if !hasSystemEventsAutomation { items.append("Automation → System Events") }
            for (browser, ok) in browserAutomation.sorted(by: { $0.key < $1.key }) where !ok {
                items.append("Automation → \(browser)")
            }
            return items
        }

        var missingSummary: String {
            let items = missingItems
            return items.isEmpty ? "All set" : items.joined(separator: ", ")
        }
    }

    private struct BrowserProbe {
        let name: String
        let bundleID: String
        let processName: String
    }

    private static let browserProbes: [BrowserProbe] = [
        BrowserProbe(name: "Arc", bundleID: "company.thebrowser.Browser", processName: "Arc"),
        BrowserProbe(name: "Safari", bundleID: "com.apple.Safari", processName: "Safari"),
        BrowserProbe(name: "Google Chrome", bundleID: "com.google.Chrome", processName: "Google Chrome"),
    ]

    static func check() -> Status {
        var browsers: [String: Bool] = [:]
        for probe in browserProbes where isRunning(bundleID: probe.bundleID) {
            browsers[probe.name] = probeRunningBrowserAutomation(processName: probe.processName)
        }
        return Status(
            hasAccessibility: AXIsProcessTrusted(),
            hasSystemEventsAutomation: probeSystemEvents(),
            browserAutomation: browsers
        )
    }

    @MainActor
    static func showPermissionsHelp() {
        let status = check()
        guard !status.isReadyForSiteBlocking else {
            let alert = NSAlert()
            alert.messageText = "Permissions look good"
            alert.informativeText = "Anchor can read browser tabs. If blocking still fails, quit and reopen Anchor after changing permissions."
            alert.runModal()
            return
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Permissions needed"
        alert.informativeText = """
        Enable in System Settings → Privacy & Security:

        • \(status.missingSummary)

        Under Automation, allow Anchor to control your browser (e.g. Arc).
        """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            openAutomationSettings()
        }
    }

    @MainActor
    private static func openAutomationSettings() {
        let modernBase = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"
        if !openSettingsURL("\(modernBase)?Privacy_Automation") {
            _ = openSettingsURL("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
        }
    }

    @discardableResult
    private static func openSettingsURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return NSWorkspace.shared.open(url)
    }

    private static func probeSystemEvents() -> Bool {
        runAppleScript("""
        tell application "System Events"
            return name of first process whose frontmost is true
        end tell
        """) != nil
    }

    private static func probeRunningBrowserAutomation(processName: String) -> Bool {
        runAppleScript("""
        tell application "System Events"
            if not (exists process "\(processName)") then return "missing"
        end tell
        tell application "\(processName)"
            return (count of windows) as text
        end tell
        """) != nil
    }

    private static func isRunning(bundleID: String) -> Bool {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .contains { !$0.isTerminated }
    }

    private static func runAppleScript(_ source: String) -> String? {
        guard let appleScript = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error).stringValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard error == nil, let result, !result.isEmpty, result != "missing" else { return nil }
        return result
    }
}
