@testable import JoinNow
import XCTest

final class AppSettingsTests: XCTestCase {
    @MainActor
    func testDefaultsEnableAlertsAndUseFiveMinuteLeadTime() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)

        XCTAssertTrue(settings.isEnabled)
        XCTAssertEqual(settings.leadTimeMinutes, 5)
        XCTAssertFalse(settings.onlyEventsWithMeetingLink)
        XCTAssertEqual(settings.alertBackgroundOpacityPercent, 30.0)
    }

    @MainActor
    func testPersistsEnabledFlagLeadTimeAndMeetingLinkFilter() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)

        settings.setEnabled(false)
        settings.setLeadTimeMinutes(10)
        settings.setOnlyEventsWithMeetingLink(true)

        let restoredSettings = AppSettings(defaults: defaults)
        XCTAssertFalse(restoredSettings.isEnabled)
        XCTAssertEqual(restoredSettings.leadTimeMinutes, 10)
        XCTAssertTrue(restoredSettings.onlyEventsWithMeetingLink)
    }

    @MainActor
    func testNormalizesUnsupportedLeadTimeToDefault() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)

        settings.setLeadTimeMinutes(42)

        XCTAssertEqual(settings.leadTimeMinutes, 5)
        XCTAssertEqual(defaults.integer(forKey: "leadTimeMinutes"), 0)
    }

    @MainActor
    func testClampsAlertBackgroundOpacity() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)

        settings.setAlertBackgroundOpacityPercent(-10)
        XCTAssertEqual(settings.alertBackgroundOpacityPercent, 0)

        settings.setAlertBackgroundOpacityPercent(150)
        XCTAssertEqual(settings.alertBackgroundOpacityPercent, 100)
    }

    @MainActor
    func testDismissPersistsByAlertIDAndStartDate() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        let startDate = Date(timeIntervalSince1970: 1_800_000_000)

        settings.dismiss(alertID: "event-1", startDate: startDate)

        let restoredSettings = AppSettings(defaults: defaults)
        XCTAssertTrue(restoredSettings.isDismissed(alertID: "event-1"))
        XCTAssertTrue(restoredSettings.isDismissed(alertID: "different-id", startDate: startDate))
    }

    private func makeDefaults() -> (suiteName: String, defaults: UserDefaults) {
        let suiteName = "JoinNowTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (suiteName, defaults)
    }
}
