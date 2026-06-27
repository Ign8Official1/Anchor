import SwiftUI
import AppKit

struct OceanMainBackdrop: View {
    var showRuins: Bool = false

    var body: some View {
        ZStack {
            OceanDepthGradient()
                .ignoresSafeArea()

            AnchorColor.abyss
                .opacity(0.35)
                .ignoresSafeArea()

            DepthVignette()
                .opacity(0.26)
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

struct OceanDecorativeBackdrop: View {
    var body: some View {
        ZStack {
            DepthParticles(layer: .back)
                .opacity(0.7)
                .ignoresSafeArea()

            AnchorColor.abyss
                .ignoresSafeArea()

            CanvasOceanFallback(showRuins: false, includeSeaLife: true)
                .opacity(0.95)
                .ignoresSafeArea()

            DepthVignette()
                .opacity(0.22)
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

struct OceanEnvironment: View {
    var sessionActive: Bool = false
    var showRuins: Bool = false
    var ambientLife: Bool = false

    @AppStorage("reduceMotion") private var reduceMotion = false

    private let coolDepthTint = Color(red: 0.04, green: 0.08, blue: 0.14)
    private let coolJellyTint = Color(red: 0.52, green: 0.66, blue: 0.8)

    private var jellyfishRecessed: Bool { !(sessionActive || ambientLife) }

    var body: some View {
        ZStack {
            OceanMainBackdrop(showRuins: showRuins)

            AureliaOceanWebView(sessionActive: sessionActive || ambientLife)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(jellyfishRecessed ? 0.56 : 1.0)
                .brightness(jellyfishRecessed ? -0.16 : 0.04)
                .saturation(jellyfishRecessed ? 0.58 : 1.08)
                .contrast(jellyfishRecessed ? 0.94 : 1.02)
                .colorMultiply(jellyfishRecessed ? coolJellyTint : .white)
                .animation(reduceMotion ? nil : .easeInOut(duration: 2.4), value: jellyfishRecessed)
                .ignoresSafeArea()

            if !jellyfishRecessed {
                SessionTimerGlow()
                    .ignoresSafeArea()
            }

            coolDepthTint
                .opacity(jellyfishRecessed ? 0.16 : 0.02)
                .animation(reduceMotion ? nil : .easeInOut(duration: 2.4), value: jellyfishRecessed)
                .ignoresSafeArea()

            DepthVignette()
                .opacity(jellyfishRecessed ? 0.42 : 0.24)
                .animation(reduceMotion ? nil : .easeInOut(duration: 2.4), value: jellyfishRecessed)
        }
        .allowsHitTesting(false)
    }
}

private struct CanvasOceanFallback: View {
    var showRuins: Bool
    var includeSeaLife: Bool

    var body: some View {
        ZStack {
            OceanDepthGradient()
            OceanPhotoLayer()
            GodRayLayer()
            BioluminescentMotes()
            RisingBubbles()
            if showRuins {
                SunkenRuinsSilhouette()
            }
            if includeSeaLife {
                RealisticSeaLifeLayer()
            }
            OceanCaustics()
            OceanMurk()
        }
    }
}

struct SunkenOceanScene: View {
    var body: some View {
        OceanEnvironment(sessionActive: false, showRuins: true)
    }
}

// MARK: - Session glow

private struct SessionTimerGlow: View {
    @State private var breathe = false

    var body: some View {
        RadialGradient(
            colors: [
                AnchorColor.bioluminescent.opacity(breathe ? 0.1 : 0.06),
                AnchorColor.plankton.opacity(0.03),
                .clear
            ],
            center: UnitPoint(x: 0.42, y: 0.38),
            startRadius: 0,
            endRadius: 480
        )
        .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: breathe)
        .onAppear { breathe = true }
    }
}

// MARK: - Layers

private struct OceanDepthGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                AnchorColor.surfaceLight.opacity(0.35),
                AnchorColor.midWater,
                AnchorColor.deepWater,
                AnchorColor.abyss
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct OceanPhotoLayer: View {
    var body: some View {
        Group {
            if let image = OceanAssets.backgroundImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(
                        LinearGradient(
                            colors: [
                                AnchorColor.midWater.opacity(0.5),
                                AnchorColor.deepWater.opacity(0.75),
                                AnchorColor.abyss.opacity(0.92)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
    }
}

private struct SunkenRuinsSilhouette: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let floorY = size.height * 0.78

                var hull = Path()
                hull.move(to: CGPoint(x: size.width * 0.08, y: floorY))
                hull.addLine(to: CGPoint(x: size.width * 0.22, y: floorY - 28))
                hull.addLine(to: CGPoint(x: size.width * 0.38, y: floorY - 18))
                hull.addLine(to: CGPoint(x: size.width * 0.42, y: floorY))
                hull.closeSubpath()
                context.fill(hull, with: .color(AnchorColor.abyss.opacity(0.85)))

                var mast = Path()
                mast.move(to: CGPoint(x: size.width * 0.28, y: floorY))
                mast.addLine(to: CGPoint(x: size.width * 0.31, y: floorY - 90))
                context.stroke(mast, with: .color(AnchorColor.abyss.opacity(0.7)), lineWidth: 4)

                for i in 0..<5 {
                    let x = size.width * (0.55 + CGFloat(i) * 0.09)
                    let h: CGFloat = 12 + CGFloat(i % 3) * 8
                    var coral = Path()
                    coral.addEllipse(in: CGRect(x: x, y: floorY - h, width: 28 + CGFloat(i % 2) * 10, height: h))
                    context.fill(coral, with: .color(AnchorColor.kelp.opacity(0.25)))
                }

                let anchorX = size.width * 0.72
                let anchorY = floorY - 8
                context.draw(
                    Text("⚓").font(.system(size: 64)),
                    at: CGPoint(x: anchorX, y: anchorY),
                    anchor: .center
                )
            }
            .blur(radius: 1.5)
            .opacity(0.55)
        }
    }
}

private struct GodRayLayer: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<5 {
                    let phase = t * 0.15 + Double(i) * 1.2
                    let sway = sin(phase) * 40
                    let x = size.width * (0.15 + CGFloat(i) * 0.17) + sway
                    var ray = Path()
                    ray.move(to: CGPoint(x: x, y: -20))
                    ray.addLine(to: CGPoint(x: x + 60, y: size.height * 0.65))
                    ray.addLine(to: CGPoint(x: x - 40, y: size.height * 0.65))
                    ray.closeSubpath()
                    context.fill(
                        ray,
                        with: .linearGradient(
                            Gradient(colors: [
                                AnchorColor.surfaceLight.opacity(0.08),
                                AnchorColor.bioluminescent.opacity(0.02),
                                .clear
                            ]),
                            startPoint: CGPoint(x: x, y: 0),
                            endPoint: CGPoint(x: x, y: size.height * 0.65)
                        )
                    )
                }
            }
            .blur(radius: 28)
        }
    }
}

private struct BioluminescentMotes: View {
    private let seeds = (0..<48).map { CGFloat($0) * 1.618 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 45.0)) { timeline in
            Canvas { context, size in
                let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate)
                for (index, seed) in seeds.enumerated() {
                    let depth = (sin(seed) * 0.5 + 0.5)
                    let x = (sin(seed * 2.3 + t * 0.04) * 0.5 + 0.5) * size.width
                    let y = (depth * 0.55 + 0.15 + cos(seed * 1.7 + t * 0.03) * 0.08) * size.height
                    let pulse = 0.5 + 0.5 * sin(t * 0.8 + seed)
                    let r: CGFloat = index % 7 == 0 ? 2.2 : (index % 3 == 0 ? 1.4 : 0.9)
                    let color = index % 5 == 0 ? AnchorColor.bioluminescent : AnchorColor.plankton
                    let opacity = (0.08 + depth * 0.18) * pulse

                    let bloom = r * 4
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - bloom, y: y - bloom, width: bloom * 2, height: bloom * 2)),
                        with: .color(color.opacity(opacity * 0.15))
                    )
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                        with: .color(color.opacity(opacity))
                    )
                }
            }
        }
    }
}

private struct RisingBubbles: View {
    private struct Bubble: Identifiable {
        let id: Int
        let xFactor: CGFloat
        let speed: CGFloat
        let size: CGFloat
        let phase: CGFloat
    }

    private static func makeBubbles() -> [Bubble] {
        var result: [Bubble] = []
        for i in 0..<22 {
            result.append(Bubble(
                id: i,
                xFactor: CGFloat(i % 9) / 9.0 + 0.05,
                speed: 0.04 + CGFloat(i % 5) * 0.012,
                size: 2 + CGFloat(i % 4),
                phase: CGFloat(i) * 2.1
            ))
        }
        return result
    }

    private let bubbles = RisingBubbles.makeBubbles()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate)
                for bubble in bubbles {
                    let progress = (t * bubble.speed + bubble.phase).truncatingRemainder(dividingBy: 1)
                    let x = size.width * (0.1 + bubble.xFactor * 0.8) + sin(t * 0.5 + bubble.phase) * 12
                    let y = size.height * (1.05 - progress * 1.1)
                    let r = bubble.size
                    context.stroke(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                        with: .color(Color.white.opacity(0.12)),
                        lineWidth: 0.6
                    )
                }
            }
        }
    }
}

private struct OceanCaustics: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            Canvas { context, size in
                let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate) * 0.25
                for row in 0..<6 {
                    for col in 0..<8 {
                        let x = CGFloat(col) / 7 * size.width + sin(t + CGFloat(row)) * 20
                        let y = CGFloat(row) / 5 * size.height * 0.5 + cos(t * 0.7 + CGFloat(col)) * 15
                        let w: CGFloat = 40 + sin(t + CGFloat(row + col)) * 15
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: w, height: w * 0.6)),
                            with: .color(AnchorColor.surfaceLight.opacity(0.025))
                        )
                    }
                }
            }
            .blur(radius: 18)
            .blendMode(.plusLighter)
        }
    }
}

private struct OceanMurk: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.clear, AnchorColor.deepWater.opacity(0.35), AnchorColor.abyss.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [AnchorColor.midWater.opacity(0.15), .clear],
                center: UnitPoint(x: 0.5, y: 0.2),
                startRadius: 0,
                endRadius: 500
            )
        }
    }
}

private struct DepthVignette: View {
    var body: some View {
        RadialGradient(
            colors: [.clear, .clear, AnchorColor.abyss.opacity(0.45), AnchorColor.abyss.opacity(0.75)],
            center: .center,
            startRadius: 120,
            endRadius: 680
        )
    }
}

// MARK: - Depth particles

struct DepthParticles: View {
    enum Layer { case back, front }

    let layer: Layer

    private var frameInterval: Double {
        layer == .front ? (1.0 / 12.0) : (1.0 / 15.0)
    }

    private struct Speck: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let drift: CGFloat
        let phase: CGFloat
    }

    private var specks: [Speck] {
        let count = layer == .back ? 42 : 20
        return (0..<count).map { i in
            let seed = CGFloat(i) * 2.399963
            return Speck(
                id: i,
                x: (sin(seed * 1.7) * 0.5 + 0.5),
                y: (cos(seed * 2.1) * 0.5 + 0.5),
                size: layer == .back ? (1.2 + sin(seed) * 1.1) : (0.5 + sin(seed) * 0.6),
                drift: 0.012 + CGFloat(i % 5) * 0.004,
                phase: seed * 3.1
            )
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: frameInterval)) { timeline in
            Canvas { context, size in
                let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate)
                let tint = layer == .back ? AnchorColor.surfaceLight : AnchorColor.bioluminescent

                for speck in specks {
                    let sway = sin(t * speck.drift * 60 + speck.phase) * (layer == .back ? 18 : 10)
                    let rise = sin(t * 0.04 + speck.phase) * (layer == .back ? 8 : 14)
                    let x = speck.x * size.width + sway
                    let y = speck.y * size.height + rise
                    let pulse = 0.55 + 0.45 * sin(t * 0.6 + speck.phase)
                    let alpha = (layer == .back ? 0.09 : 0.06) * pulse
                    let r = speck.size

                    context.fill(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                        with: .color(tint.opacity(alpha))
                    )
                }
            }
        }
        .blur(radius: layer == .back ? 2.8 : 1.4)
        .allowsHitTesting(false)
    }
}

// MARK: - Assets

enum OceanAssets {
    static var backgroundImage: NSImage? {
        let names = ["ocean-home", "ocean_home", "sunken-ocean"]
        let extensions = ["jpg", "jpeg", "png", "webp"]
        for name in names {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext),
                   let image = NSImage(contentsOf: url) {
                    return image
                }
            }
        }
        return nil
    }
}

struct OceanSheetBackground: View {
    var body: some View {
        ZStack {
            OceanDecorativeBackdrop()
            AnchorColor.abyss.opacity(0.18)
        }
    }
}

// MARK: - UI chrome

struct OceanGlassPanel<Content: View>: View {
    var padding: CGFloat = 28
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.25))
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(AnchorColor.deepWater.opacity(0.45))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AnchorColor.bioluminescent.opacity(0.35),
                                        AnchorColor.border,
                                        AnchorColor.kelp.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.75
                            )
                    )
                    .shadow(color: AnchorColor.bioluminescent.opacity(0.08), radius: 32, y: 8)
                    .shadow(color: .black.opacity(0.45), radius: 24, y: 12)
            }
    }
}

struct GlowingAnchorEmblem: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AnchorColor.bioluminescent.opacity(0.35),
                            AnchorColor.plankton.opacity(0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(pulse ? 1.08 : 0.92)
                .blur(radius: 8)

            AnchorBrandIcon(size: 88, cornerRadius: 20)
                .shadow(color: AnchorColor.bioluminescent.opacity(0.35), radius: 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct OceanPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var compact: Bool = false
    let action: () -> Void

    @State private var hovered = false
    @State private var bioPulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if !compact {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AnchorColor.bioluminescent.opacity(bioPulse ? 0.08 : 0.03))
                        .blur(radius: 18)
                        .scaleEffect(bioPulse ? 1.04 : 0.98)
                        .padding(-10)
                }

                if hovered && !compact {
                    WaterRippleOverlay()
                }

                HStack(spacing: 10) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: compact ? 15 : 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 13 : 15)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AnchorColor.deepWater.opacity(hovered ? 0.95 : 0.82),
                                    AnchorColor.abyss.opacity(0.96)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    AnchorColor.bioluminescent.opacity(
                                        hovered ? (bioPulse ? 0.65 : 0.45) : (bioPulse ? 0.38 : 0.22)
                                    ),
                                    lineWidth: hovered ? 1.2 : 0.8
                                )
                        )
                        .shadow(
                            color: AnchorColor.bioluminescent.opacity(compact ? 0.08 : (hovered ? 0.28 : 0.12)),
                            radius: compact ? 8 : (hovered ? 22 : 14),
                            y: compact ? 2 : 4
                        )
                }
                .foregroundStyle(AnchorColor.onSurface.opacity(hovered ? 1 : 0.92))
            }
        }
        .buttonStyle(.plain)
        .animation(AnchorMotion.gentle, value: hovered)
        .onHover { hovered = $0 }
        .onAppear {
            guard !compact else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                bioPulse = true
            }
        }
    }
}

private struct WaterRippleOverlay: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                let maxR = min(size.width, size.height) * 0.55
                let phase = (t * 0.28).truncatingRemainder(dividingBy: 1)
                let radius = maxR * CGFloat(phase)
                let alpha = 0.05 * (1 - phase)

                context.stroke(
                    Path(ellipseIn: CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )),
                    with: .color(AnchorColor.bioluminescent.opacity(alpha)),
                    lineWidth: 0.35
                )
            }
        }
        .allowsHitTesting(false)
    }
}
