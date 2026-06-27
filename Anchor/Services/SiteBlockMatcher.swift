import Foundation

enum SiteBlockMatcher {
    static func host(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: withScheme), let host = url.host?.lowercased(), !host.isEmpty else {
            return nil
        }
        return host
    }

    static func matches(host: String, blockedDomain: String) -> Bool {
        let domain = blockedDomain
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard !domain.isEmpty else { return false }
        if host == domain { return true }
        return host.hasSuffix(".\(domain)")
    }

    static func blockedSite(in urlString: String?, sites: [BlockedSite]) -> BlockedSite? {
        guard let urlString, !urlString.isEmpty,
              let host = host(from: urlString) else { return nil }
        return sites.first { matches(host: host, blockedDomain: $0.domain) }
    }
}
