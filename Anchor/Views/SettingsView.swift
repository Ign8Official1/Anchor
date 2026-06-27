import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBarTimer") private var showMenuBarTimer = false
    @AppStorage("reduceMotion") private var reduceMotion = false

    private var permissionStatus: PermissionChecker.Status {
        PermissionChecker.check()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                pageHeader("Settings", subtitle: "Configure Anchor's behavior and appearance.")
                VStack(alignment: .leading, spacing: 24) {
                    settingsGroup("General") {
                        Toggle("Launch at login", isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) { enabled in
                                setLaunchAtLogin(enabled)
                            }
                        Toggle("Show time in menu bar", isOn: $showMenuBarTimer)
                    }

                    settingsGroup("Permissions") {
                        permissionRow("Accessibility", ok: permissionStatus.hasAccessibility)
                        permissionRow("Automation (System Events)", ok: permissionStatus.hasSystemEventsAutomation)
                        if let arc = permissionStatus.browserAutomation["Arc"] {
                            permissionRow("Automation (Arc)", ok: arc)
                        }
                        Button("Check permissions") {
                            PermissionChecker.showPermissionsHelp()
                        }
                        .font(AnchorFont.body(13))
                    }

                    settingsGroup("Session") {
                        if let session = appState.activeSession, session.protection == .strict {
                            Button("Force end strict session") {
                                appState.forceEndStrictSession()
                            }
                            .foregroundStyle(.red)
                        }

                        if let session = appState.activeSession, session.protection == .anchored {
                            if appState.emergencyPassUsedThisWeek {
                                Text("Emergency pass used this week")
                                    .font(AnchorFont.body(14))
                                    .foregroundStyle(AnchorColor.onSurfaceMuted)
                            } else {
                                Button("Use Emergency Pass") {
                                    appState.useEmergencyPass()
                                }
                                .foregroundStyle(.red)
                            }
                        } else if appState.activeSession == nil {
                            Text("Emergency pass is available during Anchored sessions.")
                                .font(AnchorFont.body(13))
                                .foregroundStyle(AnchorColor.onSurfaceMuted)
                        }
                    }

                    settingsGroup("Appearance") {
                        Toggle("Reduce motion", isOn: $reduceMotion)
                    }

                    settingsGroup("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("0.3.0")
                                .foregroundStyle(AnchorColor.onSurfaceVariant)
                        }
                    }
                }
                .padding(32)
            }
        }
        .background(Color.clear)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func permissionRow(_ title: String, ok: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(ok ? "Enabled" : "Missing")
                .foregroundStyle(ok ? AnchorColor.success : Color.orange)
        }
    }

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(AnchorFont.label())
                .foregroundStyle(AnchorColor.onSurfaceVariant)
                .textCase(.uppercase)
                .tracking(2)
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    content()
                }
            }
        }
    }
}
