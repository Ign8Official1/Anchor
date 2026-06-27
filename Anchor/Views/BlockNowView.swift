import SwiftUI

struct BlockNowView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedBlocklistID: UUID?
    @State private var selectedProtection: ProtectionLevel = .steady
    @State private var selectedDuration: TimeInterval = 90 * 60
    @State private var isIndefinite = false

    private let durations: [(String, TimeInterval)] = [
        ("25m", 25 * 60),
        ("50m", 50 * 60),
        ("90m", 90 * 60)
    ]

    private let firmnessColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(AnchorColor.border.opacity(0.35))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    blocklistSection
                    durationSection
                    firmnessSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }

            footer
        }
        .frame(width: 440, height: 520)
        .background(sheetBackdrop)
        .onAppear {
            selectedBlocklistID = appState.blocklists.first?.id
        }
    }

    private var sheetBackdrop: some View {
        OceanSheetBackground()
    }

    // MARK: - Chrome

    private var header: some View {
        HStack {
            Text("Block Now")
                .font(AnchorFont.headline(17))
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AnchorColor.onSurfaceVariant)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(AnchorColor.surface.opacity(0.4)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().overlay(AnchorColor.border.opacity(0.2))
            OceanPrimaryButton(title: "Start Block", icon: "play.fill", compact: true) {
                startBlock()
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 14)
            .disabled(selectedBlocklist == nil)
            .opacity(selectedBlocklist == nil ? 0.45 : 1)
        }
    }

    // MARK: - Sections

    private var blocklistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Blocklist")

            VStack(spacing: 8) {
                ForEach(appState.blocklists) { list in
                    blocklistRow(list)
                }
            }
        }
    }

    private func blocklistRow(_ list: Blocklist) -> some View {
        let selected = selectedBlocklistID == list.id
        return Button {
            selectedBlocklistID = list.id
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(selected ? AnchorColor.accent : AnchorColor.onSurfaceMuted)

                if list.itemCount > 0 {
                    BlocklistIconStack(blocklist: list, iconSize: 20, maxIcons: 4)
                }

                Text(list.name)
                    .font(AnchorFont.body(14))
                    .foregroundStyle(AnchorColor.onSurface)

                Spacer()

                Text("\(list.itemCount) items")
                    .font(AnchorFont.label(11))
                    .foregroundStyle(AnchorColor.onSurfaceMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? AnchorColor.accentSoft : AnchorColor.surface.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(selected ? AnchorColor.accent.opacity(0.4) : AnchorColor.border, lineWidth: 0.75)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Duration")

            HStack(spacing: 8) {
                ForEach(durations, id: \.1) { label, value in
                    durationChip(label, value: value)
                }
                indefiniteChip
            }
        }
    }

    private var firmnessSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Firmness")

            LazyVGrid(columns: firmnessColumns, spacing: 8) {
                ForEach(ProtectionLevel.allCases) { level in
                    firmnessCard(level)
                }
            }
        }
    }

    private func firmnessCard(_ level: ProtectionLevel) -> some View {
        let selected = selectedProtection == level
        return Button {
            selectedProtection = level
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(level.title)
                        .font(AnchorFont.body(13))
                        .fontWeight(.medium)
                        .foregroundStyle(AnchorColor.onSurface)
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AnchorColor.accent)
                    }
                }
                Text(level.subtitle)
                    .font(AnchorFont.body(10))
                    .foregroundStyle(AnchorColor.onSurfaceVariant)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? AnchorColor.accentSoft : AnchorColor.surface.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(selected ? AnchorColor.accent.opacity(0.45) : AnchorColor.border, lineWidth: 0.75)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(AnchorFont.label(10))
            .foregroundStyle(AnchorColor.onSurfaceMuted)
            .textCase(.uppercase)
            .tracking(1.6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Chips

    private func durationChip(_ label: String, value: TimeInterval) -> some View {
        let selected = !isIndefinite && selectedDuration == value
        return Button {
            isIndefinite = false
            selectedDuration = value
        } label: {
            Text(label)
                .font(AnchorFont.label(12))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(chipBackground(selected: selected))
                .foregroundStyle(selected ? AnchorColor.accent : AnchorColor.onSurface.opacity(0.8))
        }
        .buttonStyle(.plain)
    }

    private var indefiniteChip: some View {
        Button {
            isIndefinite = true
        } label: {
            Text("No limit")
                .font(AnchorFont.label(12))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(chipBackground(selected: isIndefinite))
                .foregroundStyle(isIndefinite ? AnchorColor.accent : AnchorColor.onSurface.opacity(0.8))
        }
        .buttonStyle(.plain)
    }

    private func chipBackground(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(selected ? AnchorColor.accentSoft : AnchorColor.surface.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selected ? AnchorColor.accent.opacity(0.5) : AnchorColor.border, lineWidth: 0.75)
            )
    }

    // MARK: - Actions

    private var selectedBlocklist: Blocklist? {
        appState.blocklists.first { $0.id == selectedBlocklistID }
    }

    private func startBlock() {
        guard let list = selectedBlocklist else { return }
        appState.startSession(
            blocklist: list,
            protection: selectedProtection,
            duration: selectedDuration,
            isIndefinite: isIndefinite
        )
        dismiss()
    }
}
