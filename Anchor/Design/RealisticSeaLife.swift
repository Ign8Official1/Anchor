import SwiftUI
import AppKit

// MARK: - Image assets

enum CreatureAssets {
    static let jellyfish: NSImage? = load("jellyfish")
    static let fish: NSImage? = load("fish")

    private static func load(_ name: String) -> NSImage? {
        for ext in ["png", "jpg", "jpeg"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let image = NSImage(contentsOf: url) {
                return image
            }
        }
        return nil
    }
}

private struct GlowImage: View {
    let image: NSImage?
    var body: some View {
        if let image {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .blendMode(.screen)
        }
    }
}

// MARK: - Sea life layer

struct RealisticSeaLifeLayer: View {
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(JellyfishPlacement.all) { jelly in
                        DriftingJellyfish(placement: jelly, time: t, canvas: geo.size)
                    }
                    ForEach(FishPlacement.all) { fish in
                        SwimmingFish(placement: fish, time: t, canvas: geo.size)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Jellyfish

private struct DriftingJellyfish: View {
    let placement: JellyfishPlacement
    let time: TimeInterval
    let canvas: CGSize

    var body: some View {
        let pulse = 1.0 + 0.06 * sin(time * 0.9 + placement.phase)
        let squish = 1.0 - 0.05 * sin(time * 0.9 + placement.phase)
        let tilt = sin(time * 0.3 + placement.phase) * 4

        GlowImage(image: CreatureAssets.jellyfish)
            .frame(width: 150 * placement.scale, height: 220 * placement.scale)
            .scaleEffect(x: pulse, y: squish, anchor: .top)
            .rotationEffect(.degrees(tilt))
            .opacity(placement.opacity)
            .position(placement.position(in: canvas, time: time))
    }
}

// MARK: - Fish

private struct SwimmingFish: View {
    let placement: FishPlacement
    let time: TimeInterval
    let canvas: CGSize

    var body: some View {
        let wag = sin(time * 4 + placement.phase) * 3
        let facing: CGFloat = placement.goingRight ? 1 : -1

        GlowImage(image: CreatureAssets.fish)
            .frame(width: 120 * placement.scale, height: 60 * placement.scale)
            .scaleEffect(x: facing, y: 1)
            .rotationEffect(.degrees(Double(facing) * wag))
            .opacity(placement.opacity)
            .position(placement.position(in: canvas, time: time))
    }
}

// MARK: - Placements

private struct JellyfishPlacement: Identifiable {
    let id: Int
    let phase: Double
    let scale: CGFloat
    let speed: CGFloat
    let xFactor: CGFloat
    let opacity: Double

    func position(in size: CGSize, time: TimeInterval) -> CGPoint {
        let t = CGFloat(time)
        let rise = (t * speed * 0.012 + CGFloat(phase)).truncatingRemainder(dividingBy: 1.4)
        let x = size.width * xFactor + sin(t * 0.18 + CGFloat(phase)) * 50
        let y = size.height * (1.25 - rise) + cos(t * 0.22 + CGFloat(phase)) * 18
        return CGPoint(x: x, y: y)
    }

    static let all: [JellyfishPlacement] = [
        JellyfishPlacement(id: 0, phase: 0.0, scale: 1.0, speed: 0.5, xFactor: 0.28, opacity: 0.9),
        JellyfishPlacement(id: 1, phase: 2.4, scale: 0.65, speed: 0.7, xFactor: 0.72, opacity: 0.7),
        JellyfishPlacement(id: 2, phase: 4.1, scale: 0.8, speed: 0.6, xFactor: 0.52, opacity: 0.8),
        JellyfishPlacement(id: 3, phase: 5.7, scale: 0.5, speed: 0.85, xFactor: 0.86, opacity: 0.5)
    ]
}

private struct FishPlacement: Identifiable {
    let id: Int
    let phase: Double
    let scale: CGFloat
    let speed: CGFloat
    let yFactor: CGFloat
    let goingRight: Bool
    let opacity: Double

    func position(in size: CGSize, time: TimeInterval) -> CGPoint {
        let t = CGFloat(time)
        let travel = (t * speed * 0.03 + CGFloat(phase)).truncatingRemainder(dividingBy: 1.4) - 0.2
        let x = goingRight
            ? travel * size.width * 1.2 - size.width * 0.1
            : size.width * 1.1 - travel * size.width * 1.2
        let y = size.height * yFactor + sin(t * 0.5 + CGFloat(phase) * 2) * 26
        return CGPoint(x: x, y: y)
    }

    static let all: [FishPlacement] = [
        FishPlacement(id: 0, phase: 0.5, scale: 0.9, speed: 0.8, yFactor: 0.30, goingRight: true, opacity: 0.8),
        FishPlacement(id: 1, phase: 2.2, scale: 0.6, speed: 1.1, yFactor: 0.46, goingRight: false, opacity: 0.6),
        FishPlacement(id: 2, phase: 3.9, scale: 1.05, speed: 0.6, yFactor: 0.58, goingRight: true, opacity: 0.7),
        FishPlacement(id: 3, phase: 5.3, scale: 0.7, speed: 0.95, yFactor: 0.38, goingRight: false, opacity: 0.55)
    ]
}

// MARK: - Hero jellyfish (idle home centerpiece)

struct HeroJellyfishView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 1.0 + 0.05 * sin(t * 0.8)
            let squish = 1.0 - 0.04 * sin(t * 0.8)
            let bob = sin(t * 0.5) * 10
            let tilt = sin(t * 0.35) * 3

            GlowImage(image: CreatureAssets.jellyfish)
                .frame(width: 300, height: 440)
                .scaleEffect(x: pulse, y: squish, anchor: .top)
                .rotationEffect(.degrees(tilt))
                .offset(y: bob)
                .shadow(color: AnchorColor.bioluminescent.opacity(0.3), radius: 40)
        }
    }
}
