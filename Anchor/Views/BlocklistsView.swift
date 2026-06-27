import SwiftUI

struct BlocklistsView: View {
    @EnvironmentObject var appState: AppState
    @State private var editingBlocklist: Blocklist?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                pageHeader("Blocklists", subtitle: "Choose apps and websites to block during focus.")

                HStack {
                    Spacer()
                    Button {
                        editingBlocklist = Blocklist(name: "New Blocklist")
                    } label: {
                        Label("New Blocklist", systemImage: "plus")
                            .font(AnchorFont.label(13))
                            .foregroundStyle(AnchorColor.cyan)
                    }
                    .buttonStyle(.plain)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                    ForEach(appState.blocklists) { list in
                        blocklistCard(list)
                    }
                }
            }
            .padding(48)
            .frame(maxWidth: 800, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.clear)
        .sheet(item: $editingBlocklist) { list in
            BlocklistEditorView(
                blocklist: list,
                isExisting: appState.blocklists.contains(where: { $0.id == list.id })
            ) { updated in
                if appState.blocklists.contains(where: { $0.id == updated.id }) {
                    appState.updateBlocklist(updated)
                } else {
                    appState.addBlocklist(updated)
                }
            }
            .environmentObject(appState)
        }
    }

    private func blocklistCard(_ list: Blocklist) -> some View {
        Button {
            editingBlocklist = list
        } label: {
            GlassCard(padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    if list.itemCount > 0 {
                        BlocklistIconStack(blocklist: list)
                    } else {
                        Image(systemName: list.iconName)
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(AnchorColor.cyan.opacity(0.85))
                    }
                    Text(list.name)
                        .font(AnchorFont.headline(17))
                        .foregroundStyle(AnchorColor.onSurface)
                    Text(list.compactSummary)
                        .font(AnchorFont.label())
                        .foregroundStyle(AnchorColor.onSurfaceVariant)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

struct BlocklistEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State var blocklist: Blocklist
    let isExisting: Bool
    @State private var newSite = ""
    @State private var showingAppPicker = false
    let onSave: (Blocklist) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(isExisting ? "Edit blocklist" : "New blocklist")
                    .font(AnchorFont.headline(22))

                TextField("Name", text: $blocklist.name)
                    .textFieldStyle(.roundedBorder)

                sectionHeader("Apps")
                if blocklist.apps.isEmpty {
                    Text("No apps added yet")
                        .font(AnchorFont.body(13))
                        .foregroundStyle(AnchorColor.onSurfaceMuted)
                }
                ForEach(blocklist.apps) { app in
                    HStack(spacing: 12) {
                        AppIconView(bundleIdentifier: app.bundleIdentifier)
                        Text(app.name)
                            .font(AnchorFont.body(14))
                        Spacer()
                        Button {
                            blocklist.apps.removeAll { $0.id == app.id }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(AnchorColor.onSurfaceMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button("Add from Mac…") {
                    showingAppPicker = true
                }

                sectionHeader("Websites")
                Text("Opens the lock screen instead of blocked sites — works in any browser tab.")
                    .font(AnchorFont.body(12))
                    .foregroundStyle(AnchorColor.onSurfaceMuted)
                ForEach(blocklist.sites) { site in
                    HStack(spacing: 12) {
                        SiteIconView(domain: site.domain)
                        Text(site.domain)
                            .font(AnchorFont.body(14))
                        Spacer()
                        Button {
                            blocklist.sites.removeAll { $0.id == site.id }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(AnchorColor.onSurfaceMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    TextField("domain.com", text: $newSite)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        let domain = newSite.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        guard !domain.isEmpty else { return }
                        blocklist.sites.append(BlockedSite(domain: domain))
                        newSite = ""
                    }
                }

                HStack {
                    if isExisting {
                        Button("Delete") {
                            appState.deleteBlocklist(blocklist)
                            dismiss()
                        }
                        .foregroundStyle(.red)
                    }
                    Spacer()
                    Button("Cancel") { dismiss() }
                    Button("Save") {
                        let name = blocklist.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        blocklist.name = name
                        onSave(blocklist)
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(28)
        }
        .frame(width: 480, height: 540)
        .background { OceanSheetBackground() }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView(existingBundleIDs: Set(blocklist.apps.map(\.bundleIdentifier))) { app in
                guard !blocklist.apps.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) else { return }
                blocklist.apps.append(app)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AnchorFont.label())
            .foregroundStyle(AnchorColor.onSurfaceVariant)
            .textCase(.uppercase)
            .tracking(2)
    }
}
