import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                VStack(spacing: 24) {
                    statsGrid
                    HStack(alignment: .top, spacing: 20) {
                        chartCard
                        distractionsCard
                    }
                    quoteSection
                }
                .padding(32)
            }
        }
        .background(Color.clear)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .font(AnchorFont.hero(34))
            Text("Honest data from your deep sessions.")
                .font(AnchorFont.body())
                .foregroundStyle(AnchorColor.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(32)
        .padding(.top, 8)
    }

    private var statsGrid: some View {
        HStack(spacing: 16) {
            statCard("Focused", value: formatHours(appState.totalFocusSeconds), color: AnchorColor.accent)
            statCard("Saved", value: formatHours(appState.totalSavedSeconds), color: AnchorColor.tertiary)
            statCard("Blocks Resisted", value: "\(appState.totalBlocksResisted)", color: AnchorColor.secondary)
        }
    }

    private func statCard(_ title: String, value: String, color: Color) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(AnchorFont.label())
                    .foregroundStyle(AnchorColor.onSurfaceVariant)
                    .textCase(.uppercase)
                    .tracking(2)
                Text(value)
                    .font(AnchorFont.timer(32))
                    .foregroundStyle(AnchorColor.onSurface)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .blur(radius: 20)
                    .offset(x: 10, y: -10)
            }
        }
    }

    private var chartCard: some View {
        GlassCard(padding: 24) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Weekly Flow")
                        .font(AnchorFont.headline())
                    Spacer()
                    Text("Week")
                        .font(AnchorFont.label())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AnchorColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(appState.weeklyActivity()) { day in
                        VStack(spacing: 8) {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AnchorColor.surface)
                                    .frame(height: barHeight(day.focusSeconds, maxValue: 14400))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AnchorColor.accent)
                                    .frame(height: barHeight(day.focusSeconds * 0.7, maxValue: 14400))
                            }
                            Text(shortDay(day.dateKey))
                                .font(AnchorFont.label())
                                .foregroundStyle(AnchorColor.onSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 160, alignment: .bottom)
            }
        }
    }

    private var distractionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Where attention went")
                    .font(AnchorFont.headline())

                if appState.topDistractions().isEmpty {
                    Text(appState.activeSession == nil
                         ? "Start a session to track where attention goes."
                         : "No blocked app attempts yet this session.")
                        .font(AnchorFont.body(14))
                        .foregroundStyle(AnchorColor.onSurfaceVariant)
                } else {
                    ForEach(appState.topDistractions().prefix(5)) { usage in
                        HStack {
                            Image(systemName: "app.fill")
                                .foregroundStyle(AnchorColor.accent)
                                .frame(width: 32, height: 32)
                                .background(AnchorColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Text(usage.name)
                                .font(AnchorFont.body(14))
                            Spacer()
                            DurationText(interval: usage.duration)
                                .font(AnchorFont.body(13))
                                .foregroundStyle(AnchorColor.onSurfaceVariant)
                        }
                    }
                }
            }
            .frame(width: 280)
        }
    }

    private var quoteSection: some View {
        VStack(spacing: 10) {
            Rectangle().fill(AnchorColor.accent.opacity(0.4)).frame(width: 1, height: 36)
            Text("\"Attention is the rarest and purest form of generosity.\"")
                .font(AnchorFont.quote(18))
                .foregroundStyle(AnchorColor.onSurfaceVariant)
                .italic()
            Text("Simone Weil")
                .font(AnchorFont.label())
                .foregroundStyle(AnchorColor.onSurfaceMuted)
                .textCase(.uppercase)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func formatHours(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        return "\(h)h \(m)m"
    }

    private func barHeight(_ value: TimeInterval, maxValue: TimeInterval) -> CGFloat {
        guard maxValue > 0 else { return 8 }
        return Swift.max(8, CGFloat(value / maxValue) * 140)
    }

    private func shortDay(_ key: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: key) else { return "?" }
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
