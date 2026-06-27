import SwiftUI
import AppKit

enum AppIconProvider {
    static func icon(forBundleIdentifier bundleID: String) -> NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)
            ?? NSImage(size: NSSize(width: 28, height: 28))
    }
}

@MainActor
final class SiteIconCache {
    static let shared = SiteIconCache()

    private var cache: [String: NSImage] = [:]
    private var inflight: Set<String> = []

    func image(for domain: String) -> NSImage? {
        cache[domain.lowercased()]
    }

    func load(domain: String) async -> NSImage? {
        let key = domain.lowercased()
        if let cached = cache[key] { return cached }

        guard !inflight.contains(key) else { return nil }
        inflight.insert(key)
        defer { inflight.remove(key) }

        let candidates = [
            "https://icons.duckduckgo.com/ip3/\(key).ico",
            "https://www.google.com/s2/favicons?domain=\(key)&sz=64",
        ]

        for urlString in candidates {
            guard let url = URL(string: urlString) else { continue }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = NSImage(data: data), image.size.width > 1, image.size.height > 1 {
                    cache[key] = image
                    return image
                }
            } catch {
                continue
            }
        }
        return nil
    }
}

struct AppIconView: View {
    let bundleIdentifier: String
    var size: CGFloat = 28

    var body: some View {
        Image(nsImage: AppIconProvider.icon(forBundleIdentifier: bundleIdentifier))
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
    }
}

struct SiteIconView: View {
    let domain: String
    var size: CGFloat = 28

    @State private var icon: NSImage?

    var body: some View {
        Group {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .fill(AnchorColor.elevated.opacity(0.9))
                    Text(domain.prefix(1).uppercased())
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundStyle(AnchorColor.cyan.opacity(0.85))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .task(id: domain) {
            if let cached = SiteIconCache.shared.image(for: domain) {
                icon = cached
                return
            }
            icon = await SiteIconCache.shared.load(domain: domain)
        }
    }
}

struct BlocklistIconStack: View {
    let blocklist: Blocklist
    var iconSize: CGFloat = 22
    var maxIcons: Int = 5

    private var items: [(kind: String, id: String, label: String)] {
        var result: [(String, String, String)] = []
        for app in blocklist.apps.prefix(maxIcons) {
            result.append(("app", app.bundleIdentifier, app.name))
        }
        let remaining = maxIcons - result.count
        if remaining > 0 {
            for site in blocklist.sites.prefix(remaining) {
                result.append(("site", site.domain, site.domain))
            }
        }
        return result
    }

    var body: some View {
        HStack(spacing: -6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Group {
                    if item.kind == "app" {
                        AppIconView(bundleIdentifier: item.id, size: iconSize)
                    } else {
                        SiteIconView(domain: item.id, size: iconSize)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous)
                        .stroke(AnchorColor.base.opacity(0.85), lineWidth: 1.5)
                )
                .zIndex(Double(index))
            }

            let total = blocklist.apps.count + blocklist.sites.count
            if total > maxIcons {
                Text("+\(total - maxIcons)")
                    .font(AnchorFont.label(9))
                    .foregroundStyle(AnchorColor.onSurfaceMuted)
                    .padding(.leading, 8)
            }
        }
    }
}
