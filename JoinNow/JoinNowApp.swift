import SwiftUI

@main
struct JoinNowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                settings: appDelegate.settings,
                onPreview: { appDelegate.showAlertPreview() }
            )
        }
    }
}
