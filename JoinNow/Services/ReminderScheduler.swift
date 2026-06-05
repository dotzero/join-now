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
    private var shownAlertStartTimestamps = Set<Int>()

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

        let candidates = events.compactMap { event -> AlertCandidate? in
            guard shouldConsider(event: event, now: now) else {
                return nil
            }

            let meetingURL = linkExtractor.firstMeetingLink(in: event)
            if settings.onlyEventsWithMeetingLink, meetingURL == nil {
                return nil
            }

            return AlertCandidate(
                event: event,
                meetingURL: meetingURL,
                alertID: Self.alertID(for: event),
                startTimestamp: Self.alertStartTimestamp(for: event)
            )
        }

        guard let candidate = candidates.sorted(by: Self.sortCandidates).first else {
            return
        }

        shownAlertIDs.insert(candidate.alertID)
        shownAlertStartTimestamps.insert(candidate.startTimestamp)
        alertPresenter?.showAlert(for: candidate.event, meetingURL: candidate.meetingURL)
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
        let startTimestamp = Self.alertStartTimestamp(for: event)
        guard !shownAlertIDs.contains(alertID),
              !shownAlertStartTimestamps.contains(startTimestamp),
              !settings.isDismissed(alertID: alertID, startDate: event.startDate),
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

    private static func alertStartTimestamp(for event: EKEvent) -> Int {
        Int(event.startDate.timeIntervalSince1970)
    }

    private static func sortCandidates(_ lhs: AlertCandidate, _ rhs: AlertCandidate) -> Bool {
        if lhs.event.startDate != rhs.event.startDate {
            return lhs.event.startDate < rhs.event.startDate
        }

        if (lhs.meetingURL != nil) != (rhs.meetingURL != nil) {
            return lhs.meetingURL != nil
        }

        let lhsCalendarTitle = lhs.event.calendar.title
        let rhsCalendarTitle = rhs.event.calendar.title
        if lhsCalendarTitle != rhsCalendarTitle {
            return lhsCalendarTitle.localizedStandardCompare(rhsCalendarTitle) == .orderedAscending
        }

        let lhsTitle = lhs.event.title ?? ""
        let rhsTitle = rhs.event.title ?? ""
        if lhsTitle != rhsTitle {
            return lhsTitle.localizedStandardCompare(rhsTitle) == .orderedAscending
        }

        return lhs.alertID < rhs.alertID
    }
}

private struct AlertCandidate {
    let event: EKEvent
    let meetingURL: URL?
    let alertID: String
    let startTimestamp: Int
}
