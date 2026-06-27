import SwiftUI

struct SchedulesView: View {
    @EnvironmentObject var appState: AppState
    @State private var editingSchedule: Schedule?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Schedules")
                    .font(AnchorFont.display(26))
                Text("Recurring blocks that start automatically.")
                    .font(AnchorFont.body(15))
                    .foregroundStyle(AnchorColor.onSurfaceVariant)

                HStack {
                    Spacer()
                    Button {
                        guard let blocklistID = appState.blocklists.first?.id else { return }
                        editingSchedule = Schedule(name: "New Schedule", blocklistID: blocklistID)
                    } label: {
                        Label("New Schedule", systemImage: "plus")
                            .font(AnchorFont.label(13))
                            .foregroundStyle(AnchorColor.cyan)
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.blocklists.isEmpty)
                }

                if appState.blocklists.isEmpty {
                    GlassCard {
                        Text("Create a blocklist first, then add a schedule.")
                            .font(AnchorFont.body(14))
                            .foregroundStyle(AnchorColor.onSurfaceVariant)
                    }
                } else if appState.schedules.isEmpty {
                    GlassCard {
                        VStack(spacing: 14) {
                            Text("No schedules yet")
                                .font(AnchorFont.headline())
                            AnchorPrimaryButton(title: "New Schedule", icon: "plus") {
                                guard let blocklistID = appState.blocklists.first?.id else { return }
                                editingSchedule = Schedule(name: "Morning Focus", blocklistID: blocklistID)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(appState.schedules) { schedule in
                            scheduleRow(schedule)
                        }
                    }
                }
            }
            .padding(48)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.clear)
        .sheet(item: $editingSchedule) { schedule in
            ScheduleEditorView(
                schedule: schedule,
                isExisting: appState.schedules.contains(where: { $0.id == schedule.id })
            ) { updated in
                if appState.schedules.contains(where: { $0.id == updated.id }) {
                    appState.updateSchedule(updated)
                } else {
                    appState.addSchedule(updated)
                }
                appState.evaluateSchedulesNow()
            }
            .environmentObject(appState)
        }
    }

    private func scheduleRow(_ schedule: Schedule) -> some View {
        Button {
            editingSchedule = schedule
        } label: {
            GlassCard(padding: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(schedule.name)
                            .font(AnchorFont.headline(17))
                            .foregroundStyle(AnchorColor.onSurface)
                        Text(scheduleSubtitle(schedule))
                            .font(AnchorFont.body(13))
                            .foregroundStyle(AnchorColor.onSurfaceVariant)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(schedule.isActiveNow ? AnchorColor.bio : AnchorColor.onSurfaceMuted)
                            .frame(width: 7, height: 7)
                        Text(schedule.isActiveNow ? "Active" : schedule.isEnabled ? "Scheduled" : "Paused")
                            .font(AnchorFont.label())
                            .foregroundStyle(AnchorColor.onSurfaceVariant)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func scheduleSubtitle(_ schedule: Schedule) -> String {
        let days = weekdayString(schedule.weekdays)
        let start = minutesToTime(schedule.startMinutes)
        let end = minutesToTime(schedule.endMinutes)
        let listName = appState.blocklists.first { $0.id == schedule.blocklistID }?.name ?? "Blocklist"
        return "\(days) · \(start) – \(end) · \(listName)"
    }

    private func weekdayString(_ days: Set<Int>) -> String {
        let names = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sorted = days.sorted()
        if sorted == [2, 3, 4, 5, 6] { return "Mon – Fri" }
        if sorted.count == 7 { return "Daily" }
        return sorted.map { names[$0] }.joined(separator: ", ")
    }

    private func minutesToTime(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        let period = h >= 12 ? "PM" : "AM"
        let hour = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", hour, m, period)
    }
}

struct ScheduleEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State var schedule: Schedule
    let isExisting: Bool
    let onSave: (Schedule) -> Void

    @State private var startTime: Date
    @State private var endTime: Date

    init(schedule: Schedule, isExisting: Bool, onSave: @escaping (Schedule) -> Void) {
        self._schedule = State(initialValue: schedule)
        self.isExisting = isExisting
        self.onSave = onSave
        _startTime = State(initialValue: Self.date(fromMinutes: schedule.startMinutes))
        _endTime = State(initialValue: Self.date(fromMinutes: schedule.endMinutes))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(isExisting ? "Edit schedule" : "New schedule")
                    .font(AnchorFont.headline(22))

                TextField("Name", text: $schedule.name)
                    .textFieldStyle(.roundedBorder)

                Picker("Blocklist", selection: $schedule.blocklistID) {
                    ForEach(appState.blocklists) { list in
                        Text(list.name).tag(list.id)
                    }
                }

                Picker("Protection", selection: $schedule.protection) {
                    ForEach(ProtectionLevel.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }

                Toggle("Enabled", isOn: $schedule.isEnabled)

                Text("Days")
                    .font(AnchorFont.label())
                    .foregroundStyle(AnchorColor.onSurfaceMuted)
                    .textCase(.uppercase)

                weekdayPicker

                DatePicker("Starts", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("Ends", selection: $endTime, displayedComponents: .hourAndMinute)

                HStack {
                    if isExisting {
                        Button("Delete") {
                            appState.deleteSchedule(schedule)
                            dismiss()
                        }
                        .foregroundStyle(.red)
                    }
                    Spacer()
                    Button("Cancel") { dismiss() }
                    Button("Save") {
                        let name = schedule.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        schedule.name = name
                        schedule.startMinutes = Self.minutes(from: startTime)
                        schedule.endMinutes = Self.minutes(from: endTime)
                        guard schedule.endMinutes > schedule.startMinutes else { return }
                        onSave(schedule)
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(28)
        }
        .frame(width: 440, height: 520)
        .background { OceanSheetBackground() }
    }

    private var weekdayPicker: some View {
        let days: [(Int, String)] = [(1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")]
        return HStack(spacing: 8) {
            ForEach(days, id: \.0) { weekday, label in
                let selected = schedule.weekdays.contains(weekday)
                Button {
                    if selected { schedule.weekdays.remove(weekday) }
                    else { schedule.weekdays.insert(weekday) }
                } label: {
                    Text(label)
                        .font(AnchorFont.label(12))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(selected ? AnchorColor.cyan.opacity(0.2) : AnchorColor.elevated))
                        .overlay(Circle().stroke(selected ? AnchorColor.cyan.opacity(0.5) : AnchorColor.border, lineWidth: 0.5))
                        .foregroundStyle(selected ? AnchorColor.cyan : AnchorColor.onSurfaceVariant)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private static func date(fromMinutes minutes: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = minutes / 60
        components.minute = minutes % 60
        return Calendar.current.date(from: components) ?? .now
    }

    private static func minutes(from date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}

func pageHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title).font(AnchorFont.display(26))
        Text(subtitle).font(AnchorFont.body(14)).foregroundStyle(AnchorColor.onSurfaceVariant)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, 8)
}
