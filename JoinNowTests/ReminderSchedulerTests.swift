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

    private func makeDefaults() -> (suiteName: String, defaults: UserDefaults) {
        let suiteName = "JoinNowTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (suiteName, defaults)
    }

    private func makeEvent(startOffset: TimeInterval) -> EKEvent {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.title = "Planning"
        event.startDate = Date().addingTimeInterval(startOffset)
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
}

@MainActor
private final class SpyAlertPresenter: AlertPresenting {
    var isShowingAlert = false
    var showAlertResults = [true]
    private(set) var showAlertCallCount = 0

    func showAlert(for event: EKEvent, meetingURL: URL?) -> Bool {
        showAlertCallCount += 1
        if showAlertResults.isEmpty {
            return true
        }

        return showAlertResults.removeFirst()
    }
}
