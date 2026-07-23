import AppKit
import EventKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()

    let calendarService = CalendarService()
    private let linkExtractor = MeetingLinkExtractor()
    private var statusBarController: StatusBarController?
    private var alertWindowController: AlertWindowController?
    private var reminderScheduler: ReminderScheduler?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !ProcessInfo.processInfo.isRunningXCTest else {
            return
        }

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
            onQuit: { NSApp.terminate(nil) }
        )

        reminderScheduler?.start()

        Task {
            let calendars = await calendarService.calendars()
            settings.restoreCalendarSelectionIfAllDisabled(
                availableCalendarIdentifiers: Set(calendars.map(\.id))
            )
        }
    }

    private func showSettings() {
        settings.refreshLaunchAtStartupEnabled()

        if settingsWindow == nil {
            let view = SettingsView(
                settings: settings,
                calendarService: calendarService,
                onPreview: { [weak self] in self?.showAlertPreview() }
            )
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 350),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "JoinNow Settings"
            window.minSize = NSSize(width: 600, height: 340)
            window.contentView = NSHostingView(rootView: view)
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        } else {
            settingsWindow?.contentView = NSHostingView(
                rootView: SettingsView(
                    settings: settings,
                    calendarService: calendarService,
                    onPreview: { [weak self] in self?.showAlertPreview() }
                )
            )
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showAlertPreview() {
        alertWindowController?.showAlertPreview()
    }
}

private extension ProcessInfo {
    var isRunningXCTest: Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}
