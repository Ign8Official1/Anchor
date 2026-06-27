import Foundation

enum ProtectionLevel: String, Codable, CaseIterable, Identifiable {
    case gentle
    case steady
    case anchored
    case strict

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle: return "Gentle"
        case .steady: return "Steady"
        case .anchored: return "Anchored"
        case .strict: return "Strict"
        }
    }

    var subtitle: String {
        switch self {
        case .gentle: return "Snooze or end anytime"
        case .steady: return "30s wait, then snooze or end"
        case .anchored: return "Locked — emergency pass only"
        case .strict: return "Fully locked until timer ends"
        }
    }

    var snoozeDelay: TimeInterval {
        switch self {
        case .gentle: return 0
        case .steady: return 30
        case .anchored, .strict: return .infinity
        }
    }

    var pauseDelay: TimeInterval { snoozeDelay }

    var canEndEarly: Bool {
        switch self {
        case .gentle, .steady: return true
        case .anchored, .strict: return false
        }
    }

    var canSnooze: Bool {
        switch self {
        case .gentle, .steady: return true
        case .anchored, .strict: return false
        }
    }

    var allowsForceEnd: Bool {
        self == .strict
    }

    var preventsAppQuit: Bool {
        self == .strict
    }
}

struct BlockedApp: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var bundleIdentifier: String

    init(id: UUID = UUID(), name: String, bundleIdentifier: String) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
    }
}

struct BlockedSite: Codable, Identifiable, Hashable {
    var id: UUID
    var domain: String

    init(id: UUID = UUID(), domain: String) {
        self.id = id
        self.domain = domain.lowercased()
    }
}

struct Blocklist: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var apps: [BlockedApp]
    var sites: [BlockedSite]
    var iconName: String

    init(
        id: UUID = UUID(),
        name: String,
        apps: [BlockedApp] = [],
        sites: [BlockedSite] = [],
        iconName: String = "anchor"
    ) {
        self.id = id
        self.name = name
        self.apps = apps
        self.sites = sites
        self.iconName = iconName
    }

    var itemCount: Int { apps.count + sites.count }

    var appNames: [String] { apps.map(\.name) }
    var siteDomains: [String] { sites.map(\.domain) }

    var compactSummary: String {
        let items = appNames + siteDomains
        if items.isEmpty { return "No apps or sites yet" }
        if items.count <= 3 { return items.joined(separator: ", ") }
        return items.prefix(2).joined(separator: ", ") + " + \(items.count - 2) more"
    }
}

struct FocusSession: Codable, Identifiable {
    var id: UUID
    var blocklistID: UUID
    var blocklistName: String
    var protection: ProtectionLevel
    var startedAt: Date
    var endsAt: Date
    var snoozedUntil: Date?
    var isIndefinite: Bool = false

    init(
        id: UUID = UUID(),
        blocklistID: UUID,
        blocklistName: String,
        protection: ProtectionLevel,
        startedAt: Date = .now,
        duration: TimeInterval,
        isIndefinite: Bool = false
    ) {
        self.id = id
        self.blocklistID = blocklistID
        self.blocklistName = blocklistName
        self.protection = protection
        self.startedAt = startedAt
        self.isIndefinite = isIndefinite
        self.endsAt = isIndefinite ? .distantFuture : startedAt.addingTimeInterval(duration)
        self.snoozedUntil = nil
    }

    var isActive: Bool {
        if isIndefinite {
            return snoozedUntil.map { Date.now >= $0 } ?? true
        }
        return Date.now < endsAt && (snoozedUntil.map { Date.now >= $0 } ?? true)
    }

    var isSnoozed: Bool {
        guard let snoozedUntil else { return false }
        return Date.now < snoozedUntil
    }

    var elapsed: TimeInterval {
        max(0, Date.now.timeIntervalSince(startedAt))
    }

    var remaining: TimeInterval {
        if isIndefinite { return elapsed }
        return max(0, endsAt.timeIntervalSinceNow)
    }

    var timerDisplay: TimeInterval {
        isIndefinite ? elapsed : remaining
    }

    var progress: Double {
        if isIndefinite { return 0 }
        let total = endsAt.timeIntervalSince(startedAt)
        guard total > 0 else { return 1 }
        return min(1, max(0, 1 - remaining / total))
    }

    var pauseReadyAt: Date {
        startedAt.addingTimeInterval(protection.pauseDelay)
    }

    var isPauseReady: Bool {
        protection.pauseDelay == 0 || Date.now >= pauseReadyAt
    }

    var pauseCountdown: TimeInterval {
        max(0, pauseReadyAt.timeIntervalSinceNow)
    }

    var isSnoozeReady: Bool { isPauseReady }
    var snoozeCountdown: TimeInterval { pauseCountdown }

    var endLabel: String {
        if isIndefinite { return "Until you end it" }
        return "Ends \(endsAt.formatted(date: .omitted, time: .shortened))"
    }
}

struct Schedule: Codable, Identifiable {
    var id: UUID
    var name: String
    var blocklistID: UUID
    var protection: ProtectionLevel
    var weekdays: Set<Int>
    var startMinutes: Int
    var endMinutes: Int
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        blocklistID: UUID,
        protection: ProtectionLevel = .steady,
        weekdays: Set<Int> = [2, 3, 4, 5, 6],
        startMinutes: Int = 9 * 60,
        endMinutes: Int = 12 * 60,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.blocklistID = blocklistID
        self.protection = protection
        self.weekdays = weekdays
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
        self.isEnabled = isEnabled
    }

    var isActiveNow: Bool {
        guard isEnabled else { return false }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: .now)
        guard weekdays.contains(weekday) else { return false }
        let minutes = calendar.component(.hour, from: .now) * 60 + calendar.component(.minute, from: .now)
        return minutes >= startMinutes && minutes < endMinutes
    }
}

struct AnchorStone: Identifiable {
    let id: String
    let name: String
    let requirement: String
    let tier: StoneTier
    var isUnlocked: Bool
    var unlockedAt: Date?

    enum StoneTier: String {
        case common, rare, legendary
    }
}

struct ActivityDay: Identifiable, Codable {
    var id: String { dateKey }
    var dateKey: String
    var focusSeconds: TimeInterval
    var savedSeconds: TimeInterval
    var blocksResisted: Int
}

struct AppUsage: Identifiable {
    var id: String { bundleIdentifier }
    var name: String
    var bundleIdentifier: String
    var duration: TimeInterval
}

struct BlockQuote: Identifiable {
    let id = UUID()
    let text: String
    let attribution: String
}

enum AppDestination: String, CaseIterable, Identifiable {
    case overview
    case popover
    case activity
    case schedules
    case blocklists
    case collection
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .popover: return "Popover"
        case .activity: return "Activity"
        case .schedules: return "Schedules"
        case .blocklists: return "Blocklists"
        case .collection: return "Collection"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "anchor"
        case .popover: return "dock.rectangle"
        case .activity: return "chart.bar"
        case .schedules: return "calendar"
        case .blocklists: return "list.bullet.rectangle"
        case .collection: return "diamond"
        case .settings: return "gearshape"
        }
    }

    var subtitle: String {
        switch self {
        case .overview: return "Home & sessions"
        case .popover: return "Menu bar preview"
        case .activity: return "Stats & history"
        case .schedules: return "Recurring blocks"
        case .blocklists: return "Apps & sites"
        case .collection: return "Milestones"
        case .settings: return "Preferences"
        }
    }
}
