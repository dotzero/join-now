import EventKit
@testable import JoinNow
import XCTest

@MainActor
final class ReminderSchedulerTests: XCTestCase {
    func testDoesNotPresentNewAlertWhenAlertAppearsDuringCalendarFetch() async {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let presenter = SpyAlertPresenter()
        let calendarService = FakeCalendarService(events: [makeEvent(startOffset: 60)])
        calendarService.onFetch = {
            presenter.isShowingAlert = true
        }
        let scheduler = ReminderScheduler(
            settings: AppSettings(defaults: defaults),
            calendarService: calendarService,
            linkExtractor: MeetingLinkExtractor(),
            alertPresenter: presenter
        )

        await scheduler.checkUpcomingEvents()

        XCTAssertEqual(presenter.showAlertCallCount, 0)
    }

    func testDoesNotMarkEventShownWhenPresenterRejectsAlert() async {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let presenter = SpyAlertPresenter()
        presenter.showAlertResults = [false, true]
        let calendarService = FakeCalendarService(events: [makeEvent(startOffset: 60)])
        let scheduler = ReminderScheduler(
            settings: AppSettings(defaults: defaults),
            calendarService: calendarService,
            linkExtractor: MeetingLinkExtractor(),
            alertPresenter: presenter
        )

        await scheduler.checkUpcomingEvents()
        await scheduler.checkUpcomingEvents()

        XCTAssertEqual(presenter.showAlertCallCount, 2)
    }

    func testPrefersAcceptedEventOverTentativeAndDeclinedEventsAtSameStartTime() async {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let startDate = Date().addingTimeInterval(60)
        let maybeEvent = makeEvent(title: "1 Maybe planning", startDate: startDate)
        let declinedEvent = makeEvent(title: "2 Declined planning", startDate: startDate)
        let acceptedEvent = makeEvent(title: "3 Accepted planning", startDate: startDate)

        let presenter = SpyAlertPresenter()
        let calendarService = FakeCalendarService(events: [
            maybeEvent,
            declinedEvent,
            acceptedEvent
        ])
        let statusesByTitle: [String: EKParticipantStatus] = [
            "1 Maybe planning": .tentative,
            "2 Declined planning": .declined,
            "3 Accepted planning": .accepted
        ]
        let scheduler = ReminderScheduler(
            settings: AppSettings(defaults: defaults),
            calendarService: calendarService,
            linkExtractor: MeetingLinkExtractor(),
            alertPresenter: presenter,
            currentUserStatusProvider: { event in
                statusesByTitle[event.title ?? ""]
            }
        )

        await scheduler.checkUpcomingEvents()

        XCTAssertEqual(presenter.showAlertCallCount, 1)
        XCTAssertEqual(presenter.presentedEvents.first?.title, "3 Accepted planning")
    }

    func testDoesNotPresentAlertForDisabledCalendar() async {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let event = makeEvent(startOffset: 60)
        let settings = AppSettings(defaults: defaults)
        settings.setCalendarEnabled(
            false,
            calendarIdentifier: event.calendar.calendarIdentifier,
            availableCalendarIdentifiers: [event.calendar.calendarIdentifier, "other-calendar"]
        )
        let presenter = SpyAlertPresenter()
        let scheduler = ReminderScheduler(
            settings: settings,
            calendarService: FakeCalendarService(events: [event]),
            linkExtractor: MeetingLinkExtractor(),
            alertPresenter: presenter
        )

        await scheduler.checkUpcomingEvents()

        XCTAssertEqual(presenter.showAlertCallCount, 0)
    }

    private func makeDefaults() -> (suiteName: String, defaults: UserDefaults) {
        let suiteName = "JoinNowTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (suiteName, defaults)
    }

    private func makeEvent(startOffset: TimeInterval) -> EKEvent {
        makeEvent(title: "Planning", startDate: Date().addingTimeInterval(startOffset))
    }

    private func makeEvent(title: String, startDate: Date) -> EKEvent {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = event.startDate.addingTimeInterval(1800)

        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "Work"
        event.calendar = calendar

        return event
    }
}

@MainActor
private final class FakeCalendarService: CalendarEventFetching {
    var onFetch: (() -> Void)?

    private let storedEvents: [EKEvent]

    init(events: [EKEvent]) {
        self.storedEvents = events
    }

    func events(from startDate: Date, to endDate: Date) async -> [EKEvent] {
        onFetch?()
        return storedEvents
    }

    func calendars() async -> [CalendarInfo] {
        []
    }
}

@MainActor
private final class SpyAlertPresenter: AlertPresenting {
    var isShowingAlert = false
    var showAlertResults = [true]
    private(set) var showAlertCallCount = 0
    private(set) var presentedEvents = [EKEvent]()

    func showAlert(for event: EKEvent, meetingURL: URL?) -> Bool {
        showAlertCallCount += 1
        presentedEvents.append(event)
        if showAlertResults.isEmpty {
            return true
        }

        return showAlertResults.removeFirst()
    }
}
