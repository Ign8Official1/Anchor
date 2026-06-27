import AppKit

enum BlockedTabRedirector {
    static func redirectAllBlockedTabs(in bundleID: String, sites: [BlockedSite]) {
        guard let processName = browserProcessName(for: bundleID) else { return }
        guard NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first != nil else { return }
        guard !sites.isEmpty else { return }

        BlockPageServer.shared.startIfNeeded()
        let blockPrefix = BlockPageServer.shared.baseURLPrefix
        let quote = QuoteLibrary.random()
        let q = quote.text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let a = quote.attribution
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let domains = sites.map { $0.domain.lowercased() }
        let domainLiteral = domains.map { "\"\($0)\"" }.joined(separator: ", ")

        let script = """
        tell application "System Events"
            if not (exists process "\(processName)") then return
        end tell
        tell application "\(processName)"
            if (count of windows) = 0 then return
            set blockPrefix to "\(blockPrefix)"
            set quoteText to "\(q)"
            set quoteAttr to "\(a)"
            set blockedDomains to {\(domainLiteral)}
            repeat with w in windows
                repeat with t in tabs of w
                    set u to URL of t
                    if u starts with blockPrefix then
                        -- already showing lock screen
                    else
                        repeat with d in blockedDomains
                            if u contains d then
                                set URL of t to blockPrefix & "block.html?domain=" & d & "&quote=" & quoteText & "&attr=" & quoteAttr
                                exit repeat
                            end if
                        end repeat
                    end if
                end repeat
            end repeat
        end tell
        """
        runAppleScript(script)
    }

    static func redirectActiveTab(in bundleID: String, domain: String) {
        guard let processName = browserProcessName(for: bundleID) else { return }
        guard NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first != nil else { return }

        BlockPageServer.shared.startIfNeeded()
        let url = BlockPageServer.shared.pageURL(for: domain)
        let escaped = url.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")

        let tabRef = bundleID == "com.apple.Safari" ? "current tab of front window" : "active tab of front window"
        let script = """
        tell application "System Events"
            if not (exists process "\(processName)") then return
        end tell
        tell application "\(processName)"
            if (count of windows) = 0 then return
            set URL of \(tabRef) to "\(escaped)"
        end tell
        """
        runAppleScript(script)
    }

    static func isBlockPageURL(_ url: String) -> Bool {
        url.hasPrefix(BlockPageServer.shared.baseURLPrefix)
    }

    private static func browserProcessName(for bundleID: String) -> String? {
        let map: [String: String] = [
            "com.apple.Safari": "Safari",
            "com.google.Chrome": "Google Chrome",
            "com.google.Chrome.canary": "Google Chrome Canary",
            "company.thebrowser.Browser": "Arc",
            "company.thebrowser.dia": "Dia",
            "com.microsoft.edgemac": "Microsoft Edge",
            "com.brave.Browser": "Brave Browser",
            "com.operasoftware.Opera": "Opera",
            "com.vivaldi.Vivaldi": "Vivaldi",
            "org.chromium.Chromium": "Chromium",
        ]
        if let name = map[bundleID] { return name }
        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first?.localizedName
    }

    @discardableResult
    private static func runAppleScript(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error).stringValue
        return error == nil ? result : nil
    }
}
