import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedStone: AnchorStone?

    let columns = [GridItem(.adaptive(minimum: 140), spacing: 20)]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Collection")
                        .font(AnchorFont.hero(34))
                        .foregroundStyle(AnchorColor.onSurface)
                    Text("\(appState.stones.filter(\.isUnlocked).count) of \(appState.stones.count) stones set")
                        .font(AnchorFont.body(14))
                        .foregroundStyle(AnchorColor.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(appState.stones) { stone in
                        stoneCard(stone)
                    }
                }
                .padding(32)
            }
        }
        .background(Color.clear)
        .sheet(item: $selectedStone) { stone in
            stoneDetail(stone)
        }
    }

    private func stoneCard(_ stone: AnchorStone) -> some View {
        Button {
            if stone.isUnlocked { selectedStone = stone }
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            stone.isUnlocked
                                ? RadialGradient(colors: stoneGradient(stone), center: .center, startRadius: 4, endRadius: 50)
                                : RadialGradient(colors: [AnchorColor.surface, AnchorColor.void], center: .center, startRadius: 4, endRadius: 50)
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: stone.isUnlocked ? AnchorColor.accent.opacity(0.4) : .clear, radius: 16)

                    if !stone.isUnlocked {
                        Text("?")
                            .font(AnchorFont.headline(24))
                            .foregroundStyle(AnchorColor.onSurfaceMuted)
                    }
                }
                Text(stone.isUnlocked ? stone.name : "???")
                    .font(AnchorFont.label(12))
                    .foregroundStyle(stone.isUnlocked ? AnchorColor.onSurface : AnchorColor.onSurfaceMuted)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AnchorColor.elevated.opacity(stone.isUnlocked ? 0.8 : 0.4))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AnchorColor.border))
            )
        }
        .buttonStyle(.plain)
        .disabled(!stone.isUnlocked)
    }

    private func stoneDetail(_ stone: AnchorStone) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: stoneGradient(stone), center: .center, startRadius: 8, endRadius: 80))
                    .frame(width: 120, height: 120)
                    .shadow(color: AnchorColor.accent.opacity(0.5), radius: 30)
            }
            Text(stone.name)
                .font(AnchorFont.headline(24))
            Text(stone.requirement)
                .font(AnchorFont.body())
                .foregroundStyle(AnchorColor.onSurfaceVariant)
            BuoyView(size: 48)
        }
        .padding(40)
        .frame(width: 360)
        .background { OceanSheetBackground() }
    }

    private func stoneGradient(_ stone: AnchorStone) -> [Color] {
        switch stone.tier {
        case .common: return [AnchorColor.accent.opacity(0.8), AnchorColor.accent.opacity(0.2)]
        case .rare: return [AnchorColor.secondary, AnchorColor.accent.opacity(0.3)]
        case .legendary: return [AnchorColor.tertiary, AnchorColor.accent]
        }
    }
}

extension AnchorStone: Hashable {
    static func == (lhs: AnchorStone, rhs: AnchorStone) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
