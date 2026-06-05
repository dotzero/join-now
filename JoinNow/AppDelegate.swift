import AppKit
import EventKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()

    private let calendarService = CalendarService()
    private let linkExtractor = MeetingLinkExtractor()
    private var statusBarController: StatusBarController?
    private var alertWindowController: AlertWindowController?
    private var reminderScheduler: ReminderScheduler?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let alertController = AlertWindowController(settings: settings)
        self.alertWindowController = alertController

        reminderScheduler = ReminderScheduler(
            settings: settings,
            calendarService: calendarService,
            linkExtractor: linkExtractor,
            alertPresenter: alertController
        )

        statusBarController = StatusBarController(
            settings: settings,
            onOpenSettings: { [weak self] in self?.showSettings() },
            onShowTestAlert: { [weak self] in self?.showTestAlert() },
            onQuit: { NSApp.terminate(nil) }
        )

        reminderScheduler?.start()

        Task {
            _ = await calendarService.requestAccessIfNeeded()
        }
    }

    private func showSettings() {
        if settingsWindow == nil {
            let view = SettingsView(settings: settings)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 270),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "JoinNow Settings"
            window.contentView = NSHostingView(rootView: view)
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showTestAlert() {
        alertWindowController?.showTestAlert()
    }
}
