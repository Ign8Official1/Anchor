import SwiftUI

enum AnchorColor {
    static let abyss = Color(red: 0.008, green: 0.024, blue: 0.045)
    static let deepWater = Color(red: 0.016, green: 0.055, blue: 0.082)
    static let midWater = Color(red: 0.031, green: 0.094, blue: 0.125)
    static let surfaceLight = Color(red: 0.145, green: 0.420, blue: 0.520)
    static let bioluminescent = Color(red: 0.302, green: 0.910, blue: 1.0)
    static let plankton = Color(red: 0.420, green: 0.980, blue: 0.880)
    static let kelp = Color(red: 0.165, green: 0.420, blue: 0.353)

    static let base = abyss
    static let void = abyss
    static let elevated = Color.white.opacity(0.06)
    static let surface = Color.white.opacity(0.09)
    static let accent = bioluminescent
    static let accentSoft = bioluminescent.opacity(0.14)
    static let onSurface = Color(red: 0.94, green: 0.97, blue: 0.98)
    static let onSurfaceVariant = Color.white.opacity(0.58)
    static let onSurfaceMuted = Color.white.opacity(0.36)
    static let border = Color.white.opacity(0.1)
    static let edgeHighlight = bioluminescent.opacity(0.2)
    static let success = plankton

    // Legacy aliases
    static let navy = deepWater
    static let deepTeal = midWater
    static let reef = surfaceLight
    static let cyan = bioluminescent
    static let aqua = plankton
    static let bio = plankton
    static let electric = bioluminescent
    static let chrome = onSurface
    static let tertiary = onSurfaceMuted
    static let secondary = onSurfaceVariant
    static let aurora1 = bioluminescent
    static let aurora2 = plankton
    static let deepSea = deepWater
    static let bioGreen = kelp
    static let oceanTeal = surfaceLight
    static let oceanGlow = bioluminescent
}

enum AnchorFont {
    static func display(_ size: CGFloat = 32, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func hero(_ size: CGFloat = 34) -> Font {
        display(size, weight: .bold)
    }

    static func headline(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func quote(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static func timer(_ size: CGFloat = 40) -> Font {
        .system(size: size, weight: .light, design: .rounded)
    }

    static func stat(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}

enum AnchorMotion {
    static let spring = Animation.spring(response: 0.45, dampingFraction: 0.88)
    static let gentle = Animation.easeInOut(duration: 0.35)
    static let drift = Animation.easeInOut(duration: 4.5).repeatForever(autoreverses: true)
}

// MARK: - Background

struct AnchorBackdrop: View {
    var sessionActive: Bool = false
    var ambient: Bool = false

    var body: some View {
        ZStack {
            AnchorColor.base

            LinearGradient(
                colors: [Color.white.opacity(0.025), .clear, AnchorColor.base],
                startPoint: .top,
                endPoint: .bottom
            )

            if ambient {
                AmbientParticles()
            }

            if sessionActive {
                RadialGradient(
                    colors: [AnchorColor.accent.opacity(0.05), .clear],
                    center: UnitPoint(x: 0.5, y: 0.32),
                    startRadius: 0,
                    endRadius: 420
                )
                .animation(AnchorMotion.gentle, value: sessionActive)
            }

            RadialGradient(
                colors: [.clear, AnchorColor.base.opacity(0.55)],
                center: .center,
                startRadius: 280,
                endRadius: 900
            )
        }
        .allowsHitTesting(false)
    }
}

private struct AmbientParticles: View {
    private let seeds = (0..<18).map { CGFloat($0) * 1.847 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate) * 0.08
                for (index, seed) in seeds.enumerated() {
                    let x = (sin(seed + t * 0.4) * 0.5 + 0.5) * size.width
                    let y = (cos(seed * 1.2 + t * 0.3) * 0.5 + 0.5) * size.height
                    let r: CGFloat = index % 5 == 0 ? 1.4 : 0.8
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                        with: .color(AnchorColor.accent.opacity(index % 4 == 0 ? 0.07 : 0.04))
                    )
                }
            }
        }
    }
}

struct BioluminescentAttractor: Equatable {
    let point: CGPoint
    let strength: CGFloat
    var isPrimary: Bool = false
}

struct BioluminescentAttractorKey: PreferenceKey {
    static var defaultValue: [BioluminescentAttractor] = []
    static func reduce(value: inout [BioluminescentAttractor], nextValue: () -> [BioluminescentAttractor]) {
        value.append(contentsOf: nextValue())
    }
}

struct BioluminescentOcean: View {
    var attractors: [BioluminescentAttractor] = []
    var sessionActive: Bool = false
    var body: some View { AnchorBackdrop(sessionActive: sessionActive, ambient: !sessionActive) }
}

struct DeepWaterAmbience: View {
    var attractors: [BioluminescentAttractor] = []
    var sessionActive: Bool = false
    var body: some View { AnchorBackdrop(sessionActive: sessionActive) }
}

struct UnderwaterBackground: View {
    var motes: Int = 0
    var body: some View { AnchorBackdrop() }
}

// MARK: - Surfaces

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 24
    var cornerRadius: CGFloat = 16
    var glow: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.55))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(AnchorColor.elevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(AnchorColor.border, lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.35), radius: glow ? 24 : 16, y: 6)
                    .shadow(color: glow ? AnchorColor.accent.opacity(0.06) : .clear, radius: 32)
            }
    }
}

struct StatCard: View {
    let title: String
    let subtitle: String
    let value: String

    var body: some View {
        GlassCard(padding: 20, cornerRadius: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(AnchorFont.label(11))
                    .foregroundStyle(AnchorColor.onSurfaceMuted)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text(value)
                    .font(AnchorFont.stat())
                    .foregroundStyle(AnchorColor.onSurface)
                    .monospacedDigit()
                Text(subtitle)
                    .font(AnchorFont.body(12))
                    .foregroundStyle(AnchorColor.onSurfaceVariant)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MetricColumn: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AnchorFont.label(11))
                .foregroundStyle(AnchorColor.onSurfaceMuted)
                .textCase(.uppercase)
                .tracking(0.6)
            Text(value)
                .font(AnchorFont.stat(26))
                .foregroundStyle(AnchorColor.onSurface)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GlowCard<Content: View>: View {
    var padding: CGFloat = 24
    @State private var hovered = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        GlassCard(padding: padding, glow: hovered) { content() }
            .animation(AnchorMotion.spring, value: hovered)
            .onHover { hovered = $0 }
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AnchorFont.label(11))
            .foregroundStyle(AnchorColor.onSurfaceMuted)
            .textCase(.uppercase)
            .tracking(1)
    }
}

// MARK: - Controls

struct AnchorPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var prominent: Bool = false
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: prominent ? 14 : 13, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: prominent ? 15 : 14, weight: .semibold))
            }
            .frame(maxWidth: prominent ? .infinity : nil)
            .padding(.horizontal, prominent ? 24 : 16)
            .padding(.vertical, prominent ? 14 : 10)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(prominent ? AnchorColor.accent : AnchorColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AnchorColor.border, lineWidth: prominent ? 0 : 0.5)
                    )
            }
            .foregroundStyle(prominent ? Color.black.opacity(0.88) : AnchorColor.onSurface)
            .opacity(hovered ? 0.92 : 1)
        }
        .buttonStyle(.plain)
        .animation(AnchorMotion.gentle, value: hovered)
        .onHover { hovered = $0 }
    }
}

struct AnchorGhostButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(AnchorFont.label(12))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(hovered ? AnchorColor.surface : .clear)
            )
            .foregroundStyle(AnchorColor.onSurfaceVariant)
        }
        .buttonStyle(.plain)
        .animation(AnchorMotion.gentle, value: hovered)
        .onHover { hovered = $0 }
    }
}

struct ProgressBar: View {
    let progress: Double
    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AnchorColor.surface)
                    .frame(height: 4)
                Capsule()
                    .fill(AnchorColor.accent)
                    .frame(width: geo.size.width * animatedProgress, height: 4)
            }
        }
        .frame(height: 4)
        .onAppear {
            withAnimation(AnchorMotion.spring) { animatedProgress = progress }
        }
        .onChange(of: progress) { newValue in
            withAnimation(AnchorMotion.spring) { animatedProgress = newValue }
        }
    }
}

struct SessionTimerText: View {
    let interval: TimeInterval
    var size: CGFloat = 40

    var body: some View {
        Text(format(interval))
            .font(AnchorFont.timer(size))
            .foregroundStyle(AnchorColor.onSurface)
            .monospacedDigit()
    }

    private func format(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

struct DurationText: View {
    let interval: TimeInterval

    var body: some View {
        Text(format(interval)).monospacedDigit()
    }

    private func format(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

struct AnchorMark: View {
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(AnchorColor.surface)
                .frame(width: size, height: size)
            Image(systemName: "anchor")
                .font(.system(size: size * 0.38, weight: .medium))
                .foregroundStyle(AnchorColor.accent)
        }
    }
}

struct BuoyView: View {
    var size: CGFloat = 40
    var body: some View { AnchorMark(size: size) }
}

// MARK: - Modifiers

struct StaggerIn: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .onAppear {
                withAnimation(AnchorMotion.spring.delay(Double(index) * 0.04)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func staggerIn(_ index: Int) -> some View {
        modifier(StaggerIn(index: index))
    }

    func anchorBackground() -> some View {
        background(AnchorColor.base.ignoresSafeArea())
    }

    func bioluminescentSource(strength: CGFloat = 1, isPrimary: Bool = false) -> some View {
        self
    }

    func breathingGlow(active: Bool) -> some View {
        self
    }

    func underwaterFloat() -> some View {
        modifier(UnderwaterFloatModifier())
    }
}

struct UnderwaterFloatModifier: ViewModifier {
    @State private var phase = false

    func body(content: Content) -> some View {
        content
            .offset(y: phase ? -2 : 2)
            .onAppear {
                withAnimation(AnchorMotion.drift) { phase = true }
            }
    }
}

struct GrainOverlay: View {
    var body: some View { Color.clear }
}
