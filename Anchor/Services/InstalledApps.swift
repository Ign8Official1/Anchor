import AppKit
import Foundation

struct InstalledApp: Identifiable, Hashable {
    var id: String { bundleIdentifier }
    let name: String
    let bundleIdentifier: String
    let path: String

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: path)
    }
}

enum InstalledApps {
    static func discover() -> [InstalledApp] {
        var found: [String: InstalledApp] = [:]
        let directories = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications"
        ]

        for directory in directories {
            guard let entries = try? FileManager.default.contentsOfDirectory(atPath: directory) else { continue }
            for entry in entries where entry.hasSuffix(".app") {
                let path = (directory as NSString).appendingPathComponent(entry)
                guard let bundle = Bundle(path: path),
                      let bundleID = bundle.bundleIdentifier else { continue }
                let name =
                    (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? entry.replacingOccurrences(of: ".app", with: "")
                found[bundleID] = InstalledApp(name: name, bundleIdentifier: bundleID, path: path)
            }
        }

        return found.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    @MainActor
    static func pickFromPanel() -> InstalledApp? {
        let panel = NSOpenPanel()
        panel.title = "Choose an application"
        panel.message = "Select an app to add to your blocklist"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        guard let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier else { return nil }
        let name =
            (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent
        return InstalledApp(name: name, bundleIdentifier: bundleID, path: url.path)
    }
}
