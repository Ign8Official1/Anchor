import Foundation
import Combine
import AppKit

@MainActor
final class AppState: ObservableObject {
    @Published var blocklists: [Blocklist] = []
    @Published var schedules: [Schedule] = []
    @Published var activeSession: FocusSession?
    @Published var activityDays: [ActivityDay] = []
    @Published var unlockedStones: Set<String> = []
    @Published var totalFocusSeconds: TimeInterval = 0
    @Published var totalSavedSeconds: TimeInterval = 0
    @Published var totalBlocksResisted: Int = 0
    @Published var streakDays: Int = 0
    @Published var hasCompletedOnboarding: Bool = false
    @Published var showBlockOverlay: Bool = false
    @Published var overlayQuote: BlockQuote = QuoteLibrary.random()
    @Published var overlayAppName: String = ""
    @Published var selectedDestination: AppDestination = .overview
    @Published var showBlockNowSheet: Bool = false
    @Published var showMainWindow: Bool = false
    @Published var emergencyPassUsedThisWeek: Bool = false
    @Published var emergencyPassWeekKey: String = ""
    @Published private(set) var sessionClock: Date = .now

    @Published var distractionSeconds: [String: TimeInterval] = [:]

    private let store = PersistenceStore()
    private var tickTimer: Timer?
    private let blockingEngine = BlockingEngine()
    private var activeDistractionBundle: String?
    private var activeDistractionStarted: Date?

    init() {
        load()
        blockingEngine.appState = self
        startTicking()
        evaluateSchedules()
    }

    var activeBlocklist: Blocklist? {
        guard let session = activeSession else { return nil }
        return blocklists.first { $0.id == session.blocklistID }
    }

    var overlayTargetBundleID: String? {
        showBlockOverlay ? activeDistractionBundle : nil
    }

    var todayFocusSeconds: TimeInterval {
        let key = Self.dayKey(for: .now)
        let stored = activityDays.first { $0.dateKey == key }?.focusSeconds ?? 0
        guard let session = activeSession, Self.dayKey(for: session.startedAt) == key else {
            return stored
        }
        return stored + session.elapsed
    }

    var todaySavedSeconds: TimeInterval {
        let key = Self.dayKey(for: .now)
        return activityDays.first { $0.dateKey == key }?.savedSeconds ?? 0
    }

    var todayBlocksResisted: Int {
        let key = Self.dayKey(for: .now)
        return activityDays.first { $0.dateKey == key }?.blocksResisted ?? 0
    }

    var stones: [AnchorStone] {
        StoneLibrary.all(unlockedIDs: unlockedStones)
    }

    func load() {
        let snapshot = store.load()
        blocklists = snapshot.blocklists.isEmpty ? DefaultData.blocklists() : snapshot.blocklists
        schedules = snapshot.schedules
        activeSession = snapshot.activeSession
        activityDays = snapshot.activityDays
        unlockedStones = snapshot.unlockedStones
        totalFocusSeconds = snapshot.totalFocusSeconds
        totalSavedSeconds = snapshot.totalSavedSeconds
        totalBlocksResisted = snapshot.totalBlocksResisted
        streakDays = snapshot.streakDays
        hasCompletedOnboarding = snapshot.hasCompletedOnboarding
        emergencyPassUsedThisWeek = snapshot.emergencyPassUsedThisWeek
        emergencyPassWeekKey = snapshot.emergencyPassWeekKey ?? ""
        distractionSeconds = snapshot.distractionSeconds ?? [:]

        resetEmergencyPassIfNewWeek()

        // Clear stuck lock screen from a previous run.
        LockScreenController.shared.hide()
        showBlockOverlay = false

        if let session = activeSession, !session.isIndefinite, session.endsAt <= .now {
            completeSession()
        } else if activeSession != nil {
            blockingEngine.start()
        }
    }

    func save() {
        store.save(
            PersistenceSnapshot(
                blocklists: blocklists,
                schedules: schedules,
                activeSession: activeSession,
                activityDays: activityDays,
                unlockedStones: unlockedStones,
                totalFocusSeconds: totalFocusSeconds,
                totalSavedSeconds: totalSavedSeconds,
                totalBlocksResisted: totalBlocksResisted,
                streakDays: streakDays,
                hasCompletedOnboarding: hasCompletedOnboarding,
                emergencyPassUsedThisWeek: emergencyPassUsedThisWeek,
                emergencyPassWeekKey: emergencyPassWeekKey,
                distractionSeconds: distractionSeconds
            )
        )
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        save()
    }

    func startSession(blocklist: Blocklist, protection: ProtectionLevel, duration: TimeInterval, isIndefinite: Bool = false) {
        activeSession = FocusSession(
            blocklistID: blocklist.id,
            blocklistName: blocklist.name,
            protection: protection,
            duration: duration,
            isIndefinite: isIndefinite
        )
        overlayQuote = QuoteLibrary.random()
        blockingEngine.start()
        save()
    }

    func endSessionEarly() {
        guard let session = activeSession, session.protection.canEndEarly, session.isPauseReady else { return }
        completeSession()
    }

    func snooze(minutes: Int = 5) {
        guard var session = activeSession, session.protection.canSnooze, session.isPauseReady else { return }
        session.snoozedUntil = Date.now.addingTimeInterval(TimeInterval(minutes * 60))
        activeSession = session
        blockingEngine.stop()
        save()

        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(minutes * 60)) { [weak self] in
            guard let self, self.activeSession?.id == session.id else { return }
            self.activeSession?.snoozedUntil = nil
            self.blockingEngine.start()
            self.save()
        }
    }

    func useEmergencyPass() {
        guard let session = activeSession else { return }
        guard session.protection == .anchored else { return }
        guard !emergencyPassUsedThisWeek else { return }
        emergencyPassUsedThisWeek = true
        emergencyPassWeekKey = Self.weekKey(for: .now)
        activeSession = nil
        LockScreenController.shared.hide()
        showBlockOverlay = false
        blockingEngine.stop()
        save()
    }

    func ensureBlockOverlay(forApp appName: String, bundleIdentifier: String) {
        if activeDistractionBundle != bundleIdentifier {
            flushDistractionTime()
            activeDistractionBundle = bundleIdentifier
            activeDistractionStarted = .now
        }
        overlayAppName = appName
        if !LockScreenController.shared.isVisible {
            overlayQuote = QuoteLibrary.random()
            showBlockOverlay = true
            recordBlockResisted()
        }

        LockScreenController.shared.show(
            model: overlayModel(blockedName: appName),
            targetBundleID: bundleIdentifier
        ) { [weak self] in
            self?.dismissBlockOverlay(userInitiated: true)
        }
    }

    private func overlayModel(blockedName: String) -> BlockOverlayContentModel {
        let subtitle: String
        if let session = activeSession {
            subtitle = session.isIndefinite
                ? "\(session.blocklistName) · no time limit"
                : "\(session.blocklistName) · focus session active"
        } else {
            subtitle = "Focus session active"
        }
        return BlockOverlayContentModel(
            blockedName: blockedName,
            quote: overlayQuote,
            sessionSubtitle: subtitle
        )
    }

    func completeSession() {
        guard let session = activeSession else { return }
        flushDistractionTime()
        let wasAnchored = session.protection == .anchored
        let sessionStartedAt = session.startedAt
        let focused = session.isIndefinite
            ? session.elapsed
            : min(session.elapsed, session.endsAt.timeIntervalSince(session.startedAt))
        recordFocus(seconds: max(0, focused))
        updateStreak()
        activeSession = nil
        LockScreenController.shared.hide()
        showBlockOverlay = false
        blockingEngine.stop()
        evaluateMilestones(wasAnchored: wasAnchored, sessionStartedAt: sessionStartedAt)
        save()
    }

    func recordBlockResisted(savedEstimate: TimeInterval = 180) {
        totalBlocksResisted += 1
        totalSavedSeconds += savedEstimate
        updateToday { day in
            day.blocksResisted += 1
            day.savedSeconds += savedEstimate
        }
        save()
    }

    func recordFocus(seconds: TimeInterval) {
        totalFocusSeconds += seconds
        updateToday { day in
            day.focusSeconds += seconds
        }
        save()
    }

    func addBlocklist(_ blocklist: Blocklist) {
        blocklists.append(blocklist)
        save()
    }

    func updateBlocklist(_ blocklist: Blocklist) {
        guard let index = blocklists.firstIndex(where: { $0.id == blocklist.id }) else { return }
        blocklists[index] = blocklist
        save()
    }

    func deleteBlocklist(_ blocklist: Blocklist) {
        blocklists.removeAll { $0.id == blocklist.id }
        schedules.removeAll { $0.blocklistID == blocklist.id }
        save()
    }

    func addSchedule(_ schedule: Schedule) {
        schedules.append(schedule)
        save()
        evaluateSchedules()
    }

    func updateSchedule(_ schedule: Schedule) {
        guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        schedules[index] = schedule
        save()
        evaluateSchedules()
    }

    func evaluateSchedulesNow() {
        evaluateSchedules()
    }

    func deleteSchedule(_ schedule: Schedule) {
        schedules.removeAll { $0.id == schedule.id }
        save()
    }

    func topDistractions() -> [AppUsage] {
        var totals = distractionSeconds
        if let bundle = activeDistractionBundle, let start = activeDistractionStarted {
            totals[bundle, default: 0] += Date.now.timeIntervalSince(start)
        }

        let allowedBundles: Set<String>?
        if let list = activeBlocklist {
            allowedBundles = Set(list.apps.map(\.bundleIdentifier))
        } else {
            allowedBundles = nil
        }

        return totals.compactMap { bundleID, duration in
            guard duration >= 1 else { return nil }
            if let allowed = allowedBundles, !allowed.contains(bundleID) { return nil }
            return AppUsage(
                name: appName(for: bundleID),
                bundleIdentifier: bundleID,
                duration: duration
            )
        }
        .sorted { $0.duration > $1.duration }
    }

    func forceEndStrictSession() {
        guard activeSession?.protection == .strict else { return }
        completeSession()
    }

    private func appName(for bundleIdentifier: String) -> String {
        for list in blocklists {
            if let app = list.apps.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
                return app.name
            }
        }
        return bundleIdentifier
    }

    private func flushDistractionTime() {
        guard let bundle = activeDistractionBundle,
              let start = activeDistractionStarted else { return }
        let elapsed = Date.now.timeIntervalSince(start)
        guard elapsed > 0 else {
            activeDistractionBundle = nil
            activeDistractionStarted = nil
            return
        }
        distractionSeconds[bundle, default: 0] += elapsed
        activeDistractionBundle = nil
        activeDistractionStarted = nil
    }

    func weeklyActivity() -> [ActivityDay] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: .now) else { return nil }
            let key = Self.dayKey(for: date)
            if let existing = activityDays.first(where: { $0.dateKey == key }) {
                return existing
            }
            return ActivityDay(dateKey: key, focusSeconds: 0, savedSeconds: 0, blocksResisted: 0)
        }
    }

    func dismissBlockOverlay(userInitiated: Bool = false) {
        flushDistractionTime()
        LockScreenController.shared.hide()
        showBlockOverlay = false
    }

    private func startTicking() {
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        if let tickTimer {
            RunLoop.main.add(tickTimer, forMode: .common)
        }
    }

    private func tick() {
        resetEmergencyPassIfNewWeek()
        sessionClock = .now

        if let session = activeSession {
            if !session.isIndefinite, session.endsAt <= .now {
                completeSession()
                evaluateSchedules()
                return
            }
            if session.isSnoozed { return }
            activeSession = session
        } else {
            evaluateSchedules()
        }
    }

    private func evaluateSchedules() {
        guard activeSession == nil else { return }
        let calendar = Calendar.current
        let minutes = calendar.component(.hour, from: .now) * 60 + calendar.component(.minute, from: .now)

        for schedule in schedules where schedule.isActiveNow {
            guard let blocklist = blocklists.first(where: { $0.id == schedule.blocklistID }) else { continue }
            let remainingMinutes = schedule.endMinutes - minutes
            guard remainingMinutes > 0 else { continue }
            let duration = TimeInterval(remainingMinutes * 60)
            startSession(blocklist: blocklist, protection: schedule.protection, duration: duration)
            break
        }
    }

    private func evaluateMilestones(wasAnchored: Bool = false, sessionStartedAt: Date? = nil) {
        if totalFocusSeconds >= 3600 { unlockedStones.insert("hour_focused") }
        if totalFocusSeconds >= 360000 { unlockedStones.insert("hundred_hours") }
        unlockedStones.insert("first_anchor")
        if wasAnchored { unlockedStones.insert("deep_dive") }
        if streakDays >= 7 { unlockedStones.insert("seven_streak") }
        if streakDays >= 30 { unlockedStones.insert("thirty_streak") }

        if let startedAt = sessionStartedAt {
            let hour = Calendar.current.component(.hour, from: startedAt)
            if hour >= 21 || hour < 5 {
                unlockedStones.insert("night_owl")
            }
        }
    }

    private func updateStreak() {
        let minimumFocus: TimeInterval = 15 * 60
        let calendar = Calendar.current
        var streak = 0
        var day = calendar.startOfDay(for: .now)

        while true {
            let key = Self.dayKey(for: day)
            let focus = activityDays.first(where: { $0.dateKey == key })?.focusSeconds ?? 0
            guard focus >= minimumFocus else { break }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        streakDays = streak
    }

    private func resetEmergencyPassIfNewWeek() {
        let currentWeek = Self.weekKey(for: .now)
        if emergencyPassWeekKey.isEmpty {
            emergencyPassWeekKey = currentWeek
            return
        }
        if emergencyPassWeekKey != currentWeek {
            emergencyPassUsedThisWeek = false
            emergencyPassWeekKey = currentWeek
            save()
        }
    }

    private static func weekKey(for date: Date) -> String {
        let calendar = Calendar.current
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(week)"
    }

    private func updateToday(_ update: (inout ActivityDay) -> Void) {
        let key = Self.dayKey(for: .now)
        if let index = activityDays.firstIndex(where: { $0.dateKey == key }) {
            update(&activityDays[index])
        } else {
            var day = ActivityDay(dateKey: key, focusSeconds: 0, savedSeconds: 0, blocksResisted: 0)
            update(&day)
            activityDays.append(day)
        }
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct PersistenceSnapshot: Codable {
    var blocklists: [Blocklist]
    var schedules: [Schedule]
    var activeSession: FocusSession?
    var activityDays: [ActivityDay]
    var unlockedStones: Set<String>
    var totalFocusSeconds: TimeInterval
    var totalSavedSeconds: TimeInterval
    var totalBlocksResisted: Int
    var streakDays: Int
    var hasCompletedOnboarding: Bool
    var emergencyPassUsedThisWeek: Bool
    var emergencyPassWeekKey: String?
    var distractionSeconds: [String: TimeInterval]?
}

final class PersistenceStore {
    private let url: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("Anchor", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("state.json")
    }()

    func load() -> PersistenceSnapshot {
        guard let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(PersistenceSnapshot.self, from: data) else {
            return PersistenceSnapshot(
                blocklists: [],
                schedules: [],
                activeSession: nil,
                activityDays: [],
                unlockedStones: [],
                totalFocusSeconds: 0,
                totalSavedSeconds: 0,
                totalBlocksResisted: 0,
                streakDays: 0,
                hasCompletedOnboarding: false,
                emergencyPassUsedThisWeek: false,
                emergencyPassWeekKey: nil
            )
        }
        return snapshot
    }

    func save(_ snapshot: PersistenceSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
