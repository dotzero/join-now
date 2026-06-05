import AppKit
import EventKit
import SwiftUI

@MainActor
final class AlertWindowController: AlertPresenting {
    private let settings: AppSettings
    private var panel: NSPanel?

    var isShowingAlert: Bool {
        panel?.isVisible == true
    }

    init(settings: AppSettings) {
        self.settings = settings
    }

    func showAlert(for event: EKEvent, meetingURL: URL?) {
        closeAlert()

        let alertID = ReminderScheduler.alertID(for: event)
        let view = MeetingAlertView(
            title: event.title ?? "Untitled Event",
            startDate: event.startDate,
            calendarTitle: event.calendar.title,
            calendarColor: Color(nsColor: NSColor(cgColor: event.calendar.cgColor) ?? .systemRed),
            meetingURL: meetingURL,
            onJoin: { [weak self] url in
                NSWorkspace.shared.open(url)
                self?.settings.dismiss(alertID: alertID)
                self?.closeAlert()
            },
            onDismiss: { [weak self] in
                self?.settings.dismiss(alertID: alertID)
                self?.closeAlert()
            }
        )

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let panel = NSPanel(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentView = NSHostingView(rootView: view)
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .black
        panel.orderFrontRegardless()

        self.panel = panel
    }

    private func closeAlert() {
        panel?.close()
        panel = nil
    }
}
