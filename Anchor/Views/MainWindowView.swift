import SwiftUI
import AppKit

struct MainWindowView: View {
    @EnvironmentObject var appState: AppState
    @State private var selection: AppDestination = .overview

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else {
                NavigationSplitView {
                    SidebarView(selection: $selection)
                } detail: {
                    ZStack {
                        OceanEnvironment(
                            sessionActive: appState.activeSession != nil,
                            showRuins: selection == .overview && appState.activeSession == nil,
                            ambientLife: appState.activeSession != nil
                        )
                        .ignoresSafeArea()
                        detailView
                        DepthParticles(layer: .front)
                            .ignoresSafeArea()
                    }
                    .toolbar(.hidden, for: .windowToolbar)
                }
                .navigationSplitViewStyle(.balanced)
            }
        }
        .frame(minWidth: 960, minHeight: 680)
        .background(AnchorColor.abyss)
        .sheet(isPresented: $appState.showBlockNowSheet) {
            BlockNowView()
                .environmentObject(appState)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .overview:
            OverviewView()
        case .popover:
            PopoverPreviewView()
        case .activity:
            ActivityView()
        case .schedules:
            SchedulesView()
        case .blocklists:
            BlocklistsView()
        case .collection:
            CollectionView()
        case .settings:
            SettingsView()
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selection: AppDestination

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AnchorColor.deepWater, AnchorColor.abyss],
                startPoint: .top,
                endPoint: .bottom
            )

            BioluminescentMotesSidebar()

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    AnchorBrandIcon(size: 28)
                    Text("Anchor")
                        .font(AnchorFont.display(17, weight: .semibold))
                        .foregroundStyle(AnchorColor.onSurface)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 32)

                VStack(spacing: 2) {
                    ForEach(AppDestination.allCases.filter { $0 != .popover }) { dest in
                        SidebarRow(destination: dest, isSelected: selection == dest) {
                            withAnimation(AnchorMotion.spring) { selection = dest }
                        }
                    }
                }
                .padding(.horizontal, 12)

                Spacer()

                AnchorPrimaryButton(title: "Block Now", icon: "play.fill", prominent: true) {
                    appState.showBlockNowSheet = true
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .frame(minWidth: 210, maxWidth: 220)
    }
}

private struct BioluminescentMotesSidebar: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            Canvas { context, size in
                let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate) * 0.05
                for i in 0..<8 {
                    let seed = CGFloat(i) * 2.3
                    let x = (sin(seed + t) * 0.5 + 0.5) * size.width
                    let y = (cos(seed * 1.4 + t * 0.8) * 0.5 + 0.5) * size.height
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)),
                        with: .color(AnchorColor.bioluminescent.opacity(0.06))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct SidebarRow: View {
    let destination: AppDestination
    let isSelected: Bool
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: destination.icon)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .frame(width: 16)
                    .foregroundStyle(isSelected ? AnchorColor.accent : AnchorColor.onSurfaceMuted)

                Text(destination.title)
                    .font(AnchorFont.body(13))
                    .fontWeight(isSelected ? .medium : .regular)

                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AnchorColor.surface)
                } else if hovered {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AnchorColor.elevated)
                }
            }
            .foregroundStyle(isSelected ? AnchorColor.onSurface : AnchorColor.onSurfaceVariant)
        }
        .buttonStyle(.plain)
        .animation(AnchorMotion.gentle, value: hovered)
        .onHover { hovered = $0 }
    }
}
