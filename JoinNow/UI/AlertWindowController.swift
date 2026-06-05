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
        let alertID = ReminderScheduler.alertID(for: event)
        showAlert(
            presentation: AlertPresentation(
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
        )
    }

    func showTestAlert() {
        showAlert(
            presentation: AlertPresentation(
                title: "Design Review with Product Team",
                startDate: Date().addingTimeInterval(180),
                calendarTitle: "Test Calendar",
                calendarColor: .red,
                meetingURL: URL(string: "https://meet.google.com/abc-defg-hij"),
                onJoin: { [weak self] url in
                    NSWorkspace.shared.open(url)
                    self?.closeAlert()
                },
                onDismiss: { [weak self] in
                    self?.closeAlert()
                }
            )
        )
    }

    private func showAlert(presentation: AlertPresentation) {
        closeAlert()

        let view = MeetingAlertView(
            title: presentation.title,
            startDate: presentation.startDate,
            calendarTitle: presentation.calendarTitle,
            calendarColor: presentation.calendarColor,
            meetingURL: presentation.meetingURL,
            onJoin: presentation.onJoin,
            onDismiss: presentation.onDismiss
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

private struct AlertPresentation {
    let title: String
    let startDate: Date
    let calendarTitle: String
    let calendarColor: Color
    let meetingURL: URL?
    let onJoin: (URL) -> Void
    let onDismiss: () -> Void
}
