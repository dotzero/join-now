import EventKit
import Foundation

@MainActor
protocol AlertPresenting: AnyObject {
    var isShowingAlert: Bool { get }
    func showAlert(for event: EKEvent, meetingURL: URL?)
}

@MainActor
final class ReminderScheduler {
    private let settings: AppSettings
    private let calendarService: CalendarService
    private let linkExtractor: MeetingLinkExtractor
    private weak var alertPresenter: AlertPresenting?
    private var timer: Timer?
    private var shownAlertIDs = Set<String>()

    init(
        settings: AppSettings,
        calendarService: CalendarService,
        linkExtractor: MeetingLinkExtractor,
        alertPresenter: AlertPresenting
    ) {
        self.settings = settings
        self.calendarService = calendarService
        self.linkExtractor = linkExtractor
        self.alertPresenter = alertPresenter
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkUpcomingEvents()
            }
        }
        Task { await checkUpcomingEvents() }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkUpcomingEvents() async {
        guard settings.isEnabled, alertPresenter?.isShowingAlert != true else {
            return
        }

        let now = Date()
        let leadTime = TimeInterval(settings.leadTimeMinutes * 60)
        let end = now.addingTimeInterval(leadTime)
        let events = await calendarService.events(from: now, to: end)

        let candidates = events
            .filter { shouldConsider(event: $0, now: now) }
            .sorted { $0.startDate < $1.startDate }

        for event in candidates {
            let meetingURL = linkExtractor.firstMeetingLink(in: event)
            if settings.onlyEventsWithMeetingLink, meetingURL == nil {
                continue
            }

            let alertID = Self.alertID(for: event)
            shownAlertIDs.insert(alertID)
            alertPresenter?.showAlert(for: event, meetingURL: meetingURL)

            return
        }
    }

    private func shouldConsider(event: EKEvent, now: Date) -> Bool {
        guard !event.isAllDay,
              event.endDate > now,
              event.startDate >= now,
              event.status != .canceled
        else {
            return false
        }

        let alertID = Self.alertID(for: event)
        guard !shownAlertIDs.contains(alertID),
              !settings.isDismissed(alertID: alertID),
              !isDeclinedByCurrentUser(event)
        else {
            return false
        }

        return true
    }

    private func isDeclinedByCurrentUser(_ event: EKEvent) -> Bool {
        event.attendees?.contains { attendee in
            attendee.isCurrentUser && attendee.participantStatus == .declined
        } ?? false
    }

    static func alertID(for event: EKEvent) -> String {
        let identifier = event.eventIdentifier ?? event.calendarItemIdentifier
        return "\(identifier)-\(Int(event.startDate.timeIntervalSince1970))"
    }
}
