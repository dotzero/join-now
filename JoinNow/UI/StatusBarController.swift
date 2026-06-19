import AppKit
import Combine

@MainActor
final class StatusBarController {
    private let settings: AppSettings
    private let statusItem: NSStatusItem
    private let onOpenSettings: () -> Void
    private let onQuit: () -> Void
    private var cancellables = Set<AnyCancellable>()

    init(
        settings: AppSettings,
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.settings = settings
        self.onOpenSettings = onOpenSettings
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

        let image = NSImage(systemSymbolName: "calendar.and.person", accessibilityDescription: "JoinNow")
        image?.isTemplate = true

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

        menu.addItem(NSMenuItem.separator())
        addLeadTimeItems(to: menu)

        menu.addItem(NSMenuItem.separator())
        addAlertSoundItems(to: menu)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Settings",
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

    private func addLeadTimeItems(to menu: NSMenu) {
        menu.addItem(disabledHeaderItem(title: "Alert lead time"))

        for minutes in AppSettings.allowedLeadTimes {
            let item = NSMenuItem(
                title: "\(minutes) min",
                action: #selector(setLeadTime),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = minutes
            item.state = settings.leadTimeMinutes == minutes ? .on : .off
            menu.addItem(item)
        }
    }

    private func addAlertSoundItems(to menu: NSMenu) {
        menu.addItem(disabledHeaderItem(title: "Alert sound"))

        for sound in AlertSound.allCases {
            let item = NSMenuItem(
                title: sound.displayName,
                action: #selector(setAlertSound),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = sound.rawValue
            item.state = settings.alertSound == sound ? .on : .off
            menu.addItem(item)
        }
    }

    private func disabledHeaderItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc private func toggleEnabled() {
        settings.setEnabled(!settings.isEnabled)
        rebuildMenu()
    }

    @objc private func setLeadTime(_ sender: NSMenuItem) {
        guard let minutes = sender.representedObject as? Int else {
            return
        }

        settings.setLeadTimeMinutes(minutes)
        rebuildMenu()
    }

    @objc private func setAlertSound(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let sound = AlertSound(rawValue: rawValue)
        else {
            return
        }

        settings.setAlertSound(sound)
        rebuildMenu()
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func quit() {
        onQuit()
    }
}
