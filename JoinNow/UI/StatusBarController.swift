import AppKit
import Combine

@MainActor
final class StatusBarController {
    private let settings: AppSettings
    private let statusItem: NSStatusItem
    private let onOpenSettings: () -> Void
    private let onShowTestAlert: () -> Void
    private let onQuit: () -> Void
    private var cancellables = Set<AnyCancellable>()

    init(
        settings: AppSettings,
        onOpenSettings: @escaping () -> Void,
        onShowTestAlert: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.settings = settings
        self.onOpenSettings = onOpenSettings
        self.onShowTestAlert = onShowTestAlert
        self.onQuit = onQuit
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        configureStatusItemButton()
        rebuildMenu()

        settings.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.rebuildMenu()
                }
            }
            .store(in: &cancellables)
    }

    private func configureStatusItemButton() {
        guard let button = statusItem.button else {
            return
        }

        let image = NSImage(named: "ToolbarIcon")
        image?.isTemplate = true
        image?.accessibilityDescription = "JoinNow"

        button.title = ""
        button.image = image
        button.imagePosition = .imageOnly
        button.toolTip = "JoinNow"
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let enabledItem = NSMenuItem(
            title: settings.isEnabled ? "Disable" : "Enable",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabledItem.target = self
        menu.addItem(enabledItem)

        let testItem = NSMenuItem(
            title: "Test Alert",
            action: #selector(showTestAlert),
            keyEquivalent: "t"
        )
        testItem.target = self
        menu.addItem(testItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit JoinNow",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        settings.setEnabled(!settings.isEnabled)
        rebuildMenu()
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func showTestAlert() {
        onShowTestAlert()
    }

    @objc private func quit() {
        onQuit()
    }
}
