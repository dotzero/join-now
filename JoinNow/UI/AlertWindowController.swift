import AppKit
import EventKit
import SwiftUI

@MainActor
final class AlertWindowController: AlertPresenting {
    private static let talkBundleIdentifier = "kontur.talk"

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
                talkAppURL: Self.talkAppURL(meetingURL: meetingURL),
                onJoin: { [weak self] url in
                    NSWorkspace.shared.open(url)
                    self?.settings.dismiss(alertID: alertID)
                    self?.closeAlert()
                },
                onOpenTalk: { [weak self] url in
                    self?.openTalk(at: url)
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
                talkAppURL: nil,
                onJoin: { [weak self] url in
                    NSWorkspace.shared.open(url)
                    self?.closeAlert()
                },
                onOpenTalk: { [weak self] url in
                    self?.openTalk(at: url)
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
            talkAppURL: presentation.talkAppURL,
            onJoin: presentation.onJoin,
            onOpenTalk: presentation.onOpenTalk,
            onDismiss: presentation.onDismiss
        )

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let panel = NSPanel(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        let hostingView = NSHostingView(rootView: view)
        hostingView.wantsLayer = true
        hostingView.layer?.isOpaque = false
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        panel.contentView = hostingView
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.orderFrontRegardless()

        self.panel = panel
    }

    private func closeAlert() {
        panel?.close()
        panel = nil
    }

    private static func talkAppURL(meetingURL: URL?) -> URL? {
        guard meetingURL == nil else {
            return nil
        }

        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: talkBundleIdentifier)
    }

    private func openTalk(at url: URL) {
        NSWorkspace.shared.openApplication(
            at: url,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }
}

private struct AlertPresentation {
    let title: String
    let startDate: Date
    let calendarTitle: String
    let calendarColor: Color
    let meetingURL: URL?
    let talkAppURL: URL?
    let onJoin: (URL) -> Void
    let onOpenTalk: (URL) -> Void
    let onDismiss: () -> Void
}
