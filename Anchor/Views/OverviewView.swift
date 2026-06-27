import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.activeSession != nil {
                activeLayout
            } else {
                sunkenHomeLayout
            }
        }
        .background(Color.clear)
    }

    private var sunkenHomeLayout: some View {
        ZStack {
            VStack {
                homeHeader
                    .frame(maxWidth: 400, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 52)
                    .padding(.leading, 56)
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                homeActionStrip
                    .padding(.horizontal, 56)
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var homeHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Anchor")
                .font(AnchorFont.label(10))
                .foregroundStyle(AnchorColor.onSurfaceMuted.opacity(0.7))
                .textCase(.uppercase)
                .tracking(2.8)

            VStack(alignment: .leading, spacing: 5) {
                Text("Drop below the surface.")
                    .font(AnchorFont.quote(22))
                    .foregroundStyle(AnchorColor.onSurface.opacity(0.9))
                Text("Nothing reaches you here.")
                    .font(AnchorFont.quote(22))
                    .foregroundStyle(AnchorColor.bioluminescent.opacity(0.48))
            }
            .lineSpacing(2)
        }
        .floatingOnWater()
    }

    private var homeActionStrip: some View {
        HStack(alignment: .bottom, spacing: 32) {
            OceanPrimaryButton(title: "Block Now", icon: "play.fill") {
                appState.showBlockNowSheet = true
            }
            .frame(width: 220)

            if appState.blocklists.isEmpty == false {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick start")
                        .font(AnchorFont.label(9))
                        .foregroundStyle(AnchorColor.onSurfaceMuted.opacity(0.55))
                        .textCase(.uppercase)
                        .tracking(1.6)

                    HStack(spacing: 8) {
                        ForEach(appState.blocklists.prefix(3)) { list in
                            QuickStartPill(list: list) {
                                appState.startSession(
                                    blocklist: list,
                                    protection: .steady,
                                    duration: 90 * 60
                                )
                            }
                        }
                    }
                }
                .floatingOnWater()
            }

            Spacer(minLength: 0)

            homeStats
        }
    }

    private var homeStats: some View {
        HStack(spacing: 22) {
            sunkenMetric("Focus", formatDuration(appState.todayFocusSeconds))
            sunkenMetric("Saved", formatDuration(appState.todaySavedSeconds))
            sunkenMetric("Resisted", "\(appState.todayBlocksResisted)")
        }
        .floatingOnWater()
    }

    private func sunkenMetric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AnchorFont.label(8))
                .foregroundStyle(AnchorColor.onSurfaceMuted.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.8)
            Text(value)
                .font(AnchorFont.stat(16))
                .foregroundStyle(AnchorColor.onSurface.opacity(0.72))
                .monospacedDigit()
        }
    }


    private var activeLayout: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 48) {
                if let session = appState.activeSession {
                    activeSessionHero(session)
                }
                todaySection
            }
            .padding(.horizontal, 64)
            .padding(.vertical, 56)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func activeSessionHero(_ session: FocusSession) -> some View {
        let _ = appState.sessionClock
        return VStack(alignment: .leading, spacing: 20) {
            Text("Focus Session")
                .font(AnchorFont.label(11))
                .foregroundStyle(AnchorColor.bioluminescent)
                .textCase(.uppercase)
                .tracking(1.2)

            SessionTimerText(interval: session.timerDisplay, size: 72)
                .shadow(color: AnchorColor.bioluminescent.opacity(0.15), radius: 12)

            HStack(spacing: 8) {
                Text(session.blocklistName)
                    .font(AnchorFont.headline(18))
                    .foregroundStyle(AnchorColor.onSurfaceVariant)
                Text("·")
                    .foregroundStyle(AnchorColor.onSurfaceMuted)
                Text(session.protection.title)
                    .font(AnchorFont.label(12))
                    .foregroundStyle(AnchorColor.onSurfaceMuted)
            }

            if session.isIndefinite == false {
                ProgressBar(progress: session.progress)
                    .frame(maxWidth: 360)
            }

            HStack(spacing: 16) {
                Text(session.endLabel)
                    .font(AnchorFont.label(12))
                    .foregroundStyle(AnchorColor.onSurfaceMuted)

                if session.protection.canSnooze {
                    if session.isPauseReady {
                        Button("Snooze") { appState.snooze() }
                            .buttonStyle(.plain)
                            .font(AnchorFont.label(12))
                            .foregroundStyle(AnchorColor.onSurfaceVariant)
                    } else {
                        Text("Snooze in \(formatCountdown(session.pauseCountdown))")
                            .font(AnchorFont.label(11))
                            .foregroundStyle(AnchorColor.onSurfaceMuted)
                    }
                }

                if session.protection.canEndEarly {
                    if session.isPauseReady {
                        Button("End Session") { appState.endSessionEarly() }
                            .buttonStyle(.plain)
                            .font(AnchorFont.label(12))
                            .foregroundStyle(AnchorColor.onSurfaceVariant)
                    } else {
                        Text("End in \(formatCountdown(session.pauseCountdown))")
                            .font(AnchorFont.label(11))
                            .foregroundStyle(AnchorColor.onSurfaceMuted)
                    }
                }

                if session.protection == .anchored, !appState.emergencyPassUsedThisWeek {
                    Button("Emergency Pass") { appState.useEmergencyPass() }
                        .buttonStyle(.plain)
                        .font(AnchorFont.label(12))
                        .foregroundStyle(Color.orange.opacity(0.85))
                }

                if session.protection == .strict {
                    Text("Strict — locked in")
                        .font(AnchorFont.label(11))
                        .foregroundStyle(AnchorColor.onSurfaceMuted)
                }
            }
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Today")

            HStack(spacing: 0) {
                MetricColumn(label: "Focus", value: formatDuration(appState.todayFocusSeconds))
                MetricColumn(label: "Saved", value: formatDuration(appState.todaySavedSeconds))
                MetricColumn(label: "Resisted", value: "\(appState.todayBlocksResisted)")
            }
        }
        .opacity(0.55)
    }

    private func formatCountdown(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        if s >= 60 { return "\(s / 60)m \(s % 60)s" }
        return "\(s)s"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let h = m / 60
        if h > 0 { return "\(h)h \(m % 60)m" }
        if m > 0 { return "\(m)m" }
        return "0m"
    }
}

private struct QuickStartPill: View {
    let list: Blocklist
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Text(list.name)
                .font(AnchorFont.label(11))
                .foregroundStyle(AnchorColor.onSurface.opacity(hovered ? 0.9 : 0.58))
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background {
                    if hovered {
                        Capsule()
                            .fill(.ultraThinMaterial.opacity(0.18))
                            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                    }
                }
        }
        .buttonStyle(.plain)
        .animation(AnchorMotion.gentle, value: hovered)
        .onHover { hovered = $0 }
    }
}

private extension View {
    func floatingOnWater() -> some View {
        shadow(color: .black.opacity(0.55), radius: 18, y: 6)
            .shadow(color: AnchorColor.abyss.opacity(0.4), radius: 8, y: 2)
    }
}

struct BlocklistContentsView: View {
    let blocklist: Blocklist

    var body: some View {
        Text(blocklist.compactSummary)
            .font(AnchorFont.label())
            .foregroundStyle(AnchorColor.onSurfaceVariant)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
