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

    @discardableResult
    func showAlert(for event: EKEvent, meetingURL: URL?) -> Bool {
        let alertID = ReminderScheduler.alertID(for: event)
        return showAlert(
            presentation: AlertPresentation(
                title: event.title ?? "Untitled Event",
                startDate: event.startDate,
                calendarTitle: event.calendar.title,
                calendarColor: Color(nsColor: NSColor(cgColor: event.calendar.cgColor) ?? .systemRed),
                meetingURL: meetingURL,
                talkAppURL: Self.talkAppURL(meetingURL: meetingURL),
                onJoin: { [weak self] url in
                    NSWorkspace.shared.open(url)
                    self?.settings.dismiss(alertID: alertID, startDate: event.startDate)
                    self?.closeAlert()
                },
                onOpenTalk: { [weak self] url in
                    self?.openTalk(at: url)
                    self?.settings.dismiss(alertID: alertID, startDate: event.startDate)
                    self?.closeAlert()
                },
                onDismiss: { [weak self] in
                    self?.settings.dismiss(alertID: alertID, startDate: event.startDate)
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

    @discardableResult
    private func showAlert(presentation: AlertPresentation) -> Bool {
        guard !isShowingAlert else {
            return false
        }

        let view = MeetingAlertView(
            title: presentation.title,
            startDate: presentation.startDate,
            calendarTitle: presentation.calendarTitle,
            calendarColor: presentation.calendarColor,
            meetingURL: presentation.meetingURL,
            talkAppURL: presentation.talkAppURL,
            backgroundColor: settings.alertBackgroundColor,
            backgroundOpacityPercent: settings.alertBackgroundOpacityPercent,
            textColor: settings.alertTextColor,
            onJoin: presentation.onJoin,
            onOpenTalk: presentation.onOpenTalk,
            onDismiss: presentation.onDismiss
        )

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let panel = AlertPanel(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.onCancel = presentation.onDismiss

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
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()

        self.panel = panel
        return true
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

private final class AlertPanel: NSPanel {
    var onCancel: (() -> Void)?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
            return
        }

        super.keyDown(with: event)
    }
}
