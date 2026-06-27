import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            OceanEnvironment()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 32) {
                Spacer()

                AnchorBrandIcon(size: 72, cornerRadius: 16)

                Text("Welcome to\nAnchor.")
                    .font(AnchorFont.display(40, weight: .bold))
                    .foregroundStyle(AnchorColor.onSurface)

                Text("Block distracting apps, schedule focus time, and protect your attention.")
                    .font(AnchorFont.body(17))
                    .foregroundStyle(AnchorColor.onSurfaceVariant)
                    .frame(maxWidth: 440, alignment: .leading)
                    .lineSpacing(4)

                VStack(alignment: .leading, spacing: 12) {
                    onboardingPoint("Add apps from your Mac in Blocklists")
                    onboardingPoint("Start a session or set a schedule")
                    onboardingPoint("Anchor hides blocked apps while you focus")
                }
                .padding(.top, 8)

                AnchorPrimaryButton(title: "Get Started", icon: "arrow.right", prominent: true) {
                    appState.completeOnboarding()
                }
                .frame(maxWidth: 280)

                Spacer()
            }
            .padding(56)
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func onboardingPoint(_ text: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(AnchorColor.accent.opacity(0.6))
                .frame(width: 5, height: 5)
            Text(text)
                .font(AnchorFont.body(14))
                .foregroundStyle(AnchorColor.onSurfaceVariant)
        }
    }
}
