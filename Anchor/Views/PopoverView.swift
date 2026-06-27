import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            illustrationStrip
            VStack(spacing: 16) {
                if let session = appState.activeSession {
                    activeCard(session: session)
                } else {
                    idleHeader
                }

                AnchorPrimaryButton(title: "Block Now", icon: "play.fill") {
                    appState.showBlockNowSheet = true
                }

                Button {
                    WindowController.shared.openMainWindow(appState: appState)
                } label: {
                    Text("Open Anchor")
                        .font(AnchorFont.label(12))
                        .foregroundStyle(AnchorColor.onSurfaceVariant)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                todaySection
                BuoyView(size: 44)
                    .padding(.top, 4)
            }
            .padding(20)
            .offset(y: -12)
        }
        .frame(width: 360)
        .background(AnchorColor.base)
        .sheet(isPresented: $appState.showBlockNowSheet) {
            BlockNowView()
                .environmentObject(appState)
        }
    }

    private var illustrationStrip: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [AnchorColor.accent.opacity(0.35), AnchorColor.base],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .frame(height: 80)

            Image(systemName: "water.waves")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(AnchorColor.accent.opacity(0.3))
                .offset(y: 10)
        }
    }

    private var idleHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No block active")
                .font(AnchorFont.headline(18))
                .foregroundStyle(AnchorColor.onSurface)
            Text("Cast an anchor to begin.")
                .font(AnchorFont.body(14))
                .foregroundStyle(AnchorColor.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
    }

    private func activeCard(session: FocusSession) -> some View {
        let _ = appState.sessionClock
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AnchorColor.success)
                            .frame(width: 8, height: 8)
                            .shadow(color: AnchorColor.success.opacity(0.6), radius: 4)
                        Text(session.blocklistName)
                            .font(AnchorFont.headline(17))
                            .foregroundStyle(AnchorColor.onSurface)
                    }
                    Text(session.isIndefinite ? "\(session.protection.title) · no time limit" : "\(session.protection.title) · ends \(session.endsAt.formatted(date: .omitted, time: .shortened))")
                        .font(AnchorFont.body(13))
                        .foregroundStyle(AnchorColor.onSurfaceVariant)
                }
                Spacer()
            }

            SessionTimerText(interval: session.timerDisplay)

            if session.isIndefinite == false {
                VStack(spacing: 4) {
                    ProgressBar(progress: session.progress)
                    HStack {
                        Spacer()
                        Text("\(Int(session.progress * 100))%")
                            .font(AnchorFont.label())
                            .foregroundStyle(AnchorColor.onSurfaceVariant)
                    }
                }
            }

            if session.protection.canEndEarly {
                HStack(spacing: 8) {
                    if session.protection.canSnooze {
                        if session.isPauseReady {
                            AnchorGhostButton(title: "Snooze", icon: "moon.zzz") {
                                appState.snooze()
                            }
                        } else {
                            Text("Snooze in \(formatCountdown(session.pauseCountdown))")
                                .font(AnchorFont.body(12))
                                .foregroundStyle(AnchorColor.onSurfaceMuted)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    if session.isPauseReady {
                        AnchorGhostButton(title: "End Early", icon: "stop.circle") {
                            appState.endSessionEarly()
                        }
                    } else {
                        Text("End in \(formatCountdown(session.pauseCountdown))")
                            .font(AnchorFont.body(12))
                            .foregroundStyle(AnchorColor.onSurfaceMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else if session.protection == .anchored {
                VStack(spacing: 8) {
                    Text("Anchored until the timer ends.")
                        .font(AnchorFont.body(13))
                        .foregroundStyle(AnchorColor.onSurfaceMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                    if !appState.emergencyPassUsedThisWeek {
                        AnchorGhostButton(title: "Emergency Pass", icon: "lifepreserver") {
                            appState.useEmergencyPass()
                        }
                    }
                }
                .padding(.vertical, 4)
            } else {
                Text(session.protection == .strict
                     ? "Strict mode — no pausing or quitting."
                     : "This session is anchored.")
                    .font(AnchorFont.body(13))
                    .foregroundStyle(AnchorColor.onSurfaceMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today")
                .font(AnchorFont.label())
                .foregroundStyle(AnchorColor.onSurfaceVariant)
                .textCase(.uppercase)
                .tracking(2)

            statRow("Focus time", value: formatDuration(appState.todayFocusSeconds))
            statRow("Saved", value: formatDuration(appState.todaySavedSeconds))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AnchorFont.body(14))
                .foregroundStyle(AnchorColor.onSurfaceVariant)
            Spacer()
            Text(value)
                .font(AnchorFont.body(14))
                .foregroundStyle(AnchorColor.onSurface)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(AnchorColor.elevated.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AnchorColor.border, lineWidth: 1)
            )
            .shadow(color: AnchorColor.accent.opacity(0.1), radius: 20)
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
        return "\(m)m"
    }
}

struct PopoverPreviewView: View {
    var body: some View {
        ZStack {
            AnchorColor.void.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Menu Bar Popover")
                    .font(AnchorFont.headline())
                    .foregroundStyle(AnchorColor.onSurfaceVariant)
                PopoverView()
                    .environmentObject(AppState())
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.4), radius: 30)
            }
        }
    }
}
