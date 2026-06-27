import AppKit
import ApplicationServices

enum SiteBlockDetector {
    struct BlockedTabMatch {
        let site: BlockedSite
        let browserBundleID: String
        let url: String
        let isActiveTab: Bool
    }

    struct DetectionResult {
        var matches: [BlockedTabMatch]
        var runningBrowsers: Int
        var lastError: String?

        var primaryMatch: BlockedTabMatch? {
            matches.first { $0.isActiveTab } ?? matches.first
        }
    }

    private struct BrowserProfile {
        let bundleID: String
        let processName: String
    }

    private static let profiles: [BrowserProfile] = [
        BrowserProfile(bundleID: "com.apple.Safari", processName: "Safari"),
        BrowserProfile(bundleID: "com.google.Chrome", processName: "Google Chrome"),
        BrowserProfile(bundleID: "com.google.Chrome.canary", processName: "Google Chrome Canary"),
        BrowserProfile(bundleID: "company.thebrowser.Browser", processName: "Arc"),
        BrowserProfile(bundleID: "company.thebrowser.dia", processName: "Dia"),
        BrowserProfile(bundleID: "com.microsoft.edgemac", processName: "Microsoft Edge"),
        BrowserProfile(bundleID: "com.brave.Browser", processName: "Brave Browser"),
        BrowserProfile(bundleID: "com.operasoftware.Opera", processName: "Opera"),
        BrowserProfile(bundleID: "com.vivaldi.Vivaldi", processName: "Vivaldi"),
        BrowserProfile(bundleID: "org.chromium.Chromium", processName: "Chromium"),
    ]

    static func isBrowser(_ bundleID: String) -> Bool {
        profile(for: bundleID) != nil
            || bundleID.hasSuffix(".Browser")
            || bundleID.hasPrefix("company.thebrowser.")
            || bundleID.localizedCaseInsensitiveContains("chrome")
    }

    static func findBlockedTabs(in sites: [BlockedSite]) -> DetectionResult {
        guard !sites.isEmpty else {
            return DetectionResult(matches: [], runningBrowsers: 0, lastError: nil)
        }

        var allMatches: [BlockedTabMatch] = []
        var lastError: String?
        var runningCount = 0

        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            guard let bundleID = app.bundleIdentifier, isBrowser(bundleID) else { continue }
            runningCount += 1

            let activeURL = activeTabURL(for: bundleID)
            let (tabs, error) = allTabs(for: bundleID)
            if let error { lastError = error }

            for tab in tabs {
                if BlockedTabRedirector.isBlockPageURL(tab.url) { continue }
                let isActive = activeURL.map { tab.url == $0 } ?? false
                if let site = SiteBlockMatcher.blockedSite(in: tab.url, sites: sites) {
                    allMatches.append(BlockedTabMatch(site: site, browserBundleID: bundleID, url: tab.url, isActiveTab: isActive))
                } else if let site = blockedSite(inWindowTitle: tab.title, sites: sites) {
                    allMatches.append(BlockedTabMatch(site: site, browserBundleID: bundleID, url: tab.url, isActiveTab: isActive))
                }
            }
        }

        return DetectionResult(matches: allMatches, runningBrowsers: runningCount, lastError: lastError)
    }

    static func blockedSite(inWindowTitle title: String, sites: [BlockedSite]) -> BlockedSite? {
        let lower = title.lowercased()
        guard !lower.isEmpty else { return nil }

        for site in sites {
            let domain = site.domain.lowercased()
            if lower.contains(domain) { return site }
            let label = domain.split(separator: ".").first.map(String.init) ?? domain
            if label.count >= 4, lower.contains(label) { return site }
            if domain == "x.com", lower.contains("twitter") || lower == "x" || lower.hasPrefix("x ") { return site }
        }
        return nil
    }

    private struct TabInfo {
        let url: String
        let title: String
    }

    private static func activeTabURL(for bundleID: String) -> String? {
        guard let processName = processName(for: bundleID) else { return nil }
        let tabRef = bundleID == "com.apple.Safari" ? "current tab of front window" : "active tab of front window"
        let script = """
        tell application "System Events"
            if not (exists process "\(processName)") then return ""
        end tell
        tell application "\(processName)"
            if (count of windows) = 0 then return ""
            return URL of \(tabRef)
        end tell
        """
        let (lines, _) = runAppleScriptLinesWithError(script)
        return lines.first
    }

    private static func allTabs(for bundleID: String) -> ([TabInfo], String?) {
        guard let processName = processName(for: bundleID) else { return ([], nil) }
        guard NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first != nil else {
            return ([], nil)
        }

        let script = """
        tell application "System Events"
            if not (exists process "\(processName)") then return ""
        end tell
        tell application "\(processName)"
            if (count of windows) = 0 then return ""
            set output to ""
            repeat with w in windows
                repeat with t in tabs of w
                    set u to URL of t
                    set n to name of t
                    if output is not "" then set output to output & linefeed
                    set output to output & u & tab & n
                end repeat
            end repeat
            return output
        end tell
        """
        let (lines, error) = runAppleScriptLinesWithError(script)
        let tabs = lines.compactMap { line -> TabInfo? in
            let parts = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            guard !parts.isEmpty else { return nil }
            let url = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            let title = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""
            guard !url.isEmpty || !title.isEmpty else { return nil }
            return TabInfo(url: url, title: title)
        }
        return (tabs, error)
    }

    private static func processName(for bundleID: String) -> String? {
        if let profile = profile(for: bundleID) { return profile.processName }
        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first?.localizedName
    }

    private static func profile(for bundleID: String) -> BrowserProfile? {
        profiles.first { $0.bundleID == bundleID }
    }

    private static func runAppleScriptLinesWithError(_ source: String) -> (lines: [String], error: String?) {
        guard let script = NSAppleScript(source: source) else { return ([], "Invalid script") }
        var error: NSDictionary?
        guard let result = script.executeAndReturnError(&error).stringValue else {
            return ([], appleScriptErrorMessage(error))
        }
        guard error == nil else { return ([], appleScriptErrorMessage(error)) }
        let lines = result
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "missing value" }
        return (lines, nil)
    }

    private static func appleScriptErrorMessage(_ error: NSDictionary?) -> String? {
        guard let error else { return nil }
        let message = error[NSAppleScript.errorMessage] as? String ?? "AppleScript failed"
        let number = error[NSAppleScript.errorNumber] as? Int
        if let number { return "\(message) (\(number))" }
        return message
    }
}
