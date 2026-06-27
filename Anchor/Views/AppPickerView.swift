import SwiftUI
import UniformTypeIdentifiers

struct AppPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let existingBundleIDs: Set<String>
    let onSelect: (BlockedApp) -> Void

    @State private var apps: [InstalledApp] = []
    @State private var query = ""

    private var filtered: [InstalledApp] {
        guard !query.isEmpty else { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.bundleIdentifier.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add application")
                .font(AnchorFont.headline(20))

            TextField("Search apps", text: $query)
                .textFieldStyle(.roundedBorder)

            List(filtered) { app in
                Button {
                    onSelect(BlockedApp(name: app.name, bundleIdentifier: app.bundleIdentifier))
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(nsImage: app.icon)
                            .resizable()
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                                .foregroundStyle(AnchorColor.onSurface)
                            Text(app.bundleIdentifier)
                                .font(AnchorFont.label())
                                .foregroundStyle(AnchorColor.onSurfaceMuted)
                        }
                        Spacer()
                        if existingBundleIDs.contains(app.bundleIdentifier) {
                            Text("Added")
                                .font(AnchorFont.label())
                                .foregroundStyle(AnchorColor.onSurfaceMuted)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(existingBundleIDs.contains(app.bundleIdentifier))
            }
            .listStyle(.plain)

            HStack {
                Button("Browse…") {
                    if let app = InstalledApps.pickFromPanel(),
                       !existingBundleIDs.contains(app.bundleIdentifier) {
                        onSelect(BlockedApp(name: app.name, bundleIdentifier: app.bundleIdentifier))
                        dismiss()
                    }
                }
                Spacer()
                Button("Cancel") { dismiss() }
            }
        }
        .padding(24)
        .frame(width: 520, height: 520)
        .background { OceanSheetBackground() }
        .onAppear { apps = InstalledApps.discover() }
    }
}
