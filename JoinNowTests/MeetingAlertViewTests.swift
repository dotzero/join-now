@testable import JoinNow
import XCTest

final class MeetingAlertViewTests: XCTestCase {
    func testCountdownShowsOnlyMinutesWhenAtLeastOneMinuteRemains() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let startDate = now.addingTimeInterval(125)

        XCTAssertEqual(
            AlertCountdownText.title(startDate: startDate, now: now),
            "Meeting starts in 3 min"
        )
    }

    func testCountdownShowsOnlySecondsWhenLessThanMinuteRemains() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let startDate = now.addingTimeInterval(42)

        XCTAssertEqual(
            AlertCountdownText.title(startDate: startDate, now: now),
            "Meeting starts in 42 sec"
        )
    }

    func testCountdownShowsStartingNowAroundStartTime() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let startDate = now.addingTimeInterval(-30)

        XCTAssertEqual(
            AlertCountdownText.title(startDate: startDate, now: now),
            "Meeting starting now"
        )
    }

    func testCountdownShowsMinutesSinceStart() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let startDate = now.addingTimeInterval(-125)

        XCTAssertEqual(
            AlertCountdownText.title(startDate: startDate, now: now),
            "Meeting started 2 min ago"
        )
    }
}
