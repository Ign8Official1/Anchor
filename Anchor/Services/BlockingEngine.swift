import AppKit
import Foundation

@MainActor
final class BlockingEngine {
    weak var appState: AppState?
    private var monitorTimer: Timer?
    private var isPolling = false

    func start() {
        BlockPageServer.shared.startIfNeeded()
        monitorTimer?.invalidate()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.schedulePoll()
            }
        }
        if let monitorTimer {
            RunLoop.main.add(monitorTimer, forMode: .common)
        }
        schedulePoll()
    }

    func stop() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        BlockPageServer.shared.stop()
    }

    private func schedulePoll() {
        guard !isPolling else { return }
        guard let appState else { return }

        let session = appState.activeSession
        let blocklist = appState.activeBlocklist
        isPolling = true

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let result = Self.scan(session: session, blocklist: blocklist)
            DispatchQueue.main.async {
                guard let self else { return }
                self.isPolling = false
                self.apply(result, appState: appState)
            }
        }
    }

    private struct ScanResult {
        var blockedApp: BlockedApp?
        var blockedAppBundleID: String?
        var siteMatches: [SiteBlockDetector.BlockedTabMatch]
        var sites: [BlockedSite]
    }

    private static func scan(session: FocusSession?, blocklist: Blocklist?) -> ScanResult {
        guard let session, !session.isSnoozed, let blocklist else {
            return ScanResult(blockedApp: nil, blockedAppBundleID: nil, siteMatches: [], sites: [])
        }

        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let bundleID = frontApp.bundleIdentifier,
           bundleID != Bundle.main.bundleIdentifier,
           let blockedApp = blocklist.apps.first(where: { $0.bundleIdentifier == bundleID }) {
            return ScanResult(blockedApp: blockedApp, blockedAppBundleID: bundleID, siteMatches: [], sites: [])
        }

        guard !blocklist.sites.isEmpty else {
            return ScanResult(blockedApp: nil, blockedAppBundleID: nil, siteMatches: [], sites: [])
        }

        let detection = SiteBlockDetector.findBlockedTabs(in: blocklist.sites)
        return ScanResult(
            blockedApp: nil,
            blockedAppBundleID: nil,
            siteMatches: detection.matches,
            sites: blocklist.sites
        )
    }

    private func apply(_ result: ScanResult, appState: AppState) {
        guard appState.activeSession != nil, !(appState.activeSession?.isSnoozed ?? true) else {
            LockScreenController.shared.hide()
            return
        }

        if let app = result.blockedApp, let bundleID = result.blockedAppBundleID {
            appState.ensureBlockOverlay(forApp: app.name, bundleIdentifier: bundleID)
            return
        }

        LockScreenController.shared.hide()

        guard !result.siteMatches.isEmpty else { return }

        let browsers = Set(result.siteMatches.map(\.browserBundleID))
        for bundleID in browsers {
            BlockedTabRedirector.redirectAllBlockedTabs(in: bundleID, sites: result.sites)
        }
    }
}
