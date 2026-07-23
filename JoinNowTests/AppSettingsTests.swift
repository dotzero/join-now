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
        XCTAssertEqual(settings.alertSound, .hero)
        XCTAssertEqual(settings.alertBackgroundOpacityPercent, 80.0)
    }

    @MainActor
    func testReadsLaunchAtStartupStateFromService() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = MockLaunchAtLoginService(isEnabled: true)
        let settings = AppSettings(defaults: defaults, launchAtLoginService: service)

        XCTAssertTrue(settings.launchAtStartupEnabled)
    }

    @MainActor
    func testUpdatesLaunchAtStartupService() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = MockLaunchAtLoginService(isEnabled: false)
        let settings = AppSettings(defaults: defaults, launchAtLoginService: service)

        settings.setLaunchAtStartupEnabled(true)

        XCTAssertTrue(settings.launchAtStartupEnabled)
        XCTAssertTrue(service.isEnabled)
        XCTAssertNil(settings.launchAtStartupErrorMessage)
    }

    @MainActor
    func testRestoresLaunchAtStartupStateWhenServiceUpdateFails() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = MockLaunchAtLoginService(isEnabled: false)
        service.error = MockLaunchAtLoginService.Error.updateFailed
        let settings = AppSettings(defaults: defaults, launchAtLoginService: service)

        settings.setLaunchAtStartupEnabled(true)

        XCTAssertFalse(settings.launchAtStartupEnabled)
        XCTAssertNotNil(settings.launchAtStartupErrorMessage)
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
    func testPersistsAlertSound() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)

        settings.setAlertSound(.glass)
        XCTAssertEqual(AppSettings(defaults: defaults).alertSound, .glass)

        settings.setAlertSound(.none)
        XCTAssertEqual(AppSettings(defaults: defaults).alertSound, .none)
    }

    @MainActor
    func testNormalizesUnsupportedAlertSoundToDefault() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("chime", forKey: "alertSound")

        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.alertSound, .hero)
    }

    @MainActor
    func testDismissPersistsByAlertIDAndStartDate() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        let startDate = Date(timeIntervalSince1970: 1_800_000_000)

        let alertID = "event-1800000000"
        settings.dismiss(alertID: alertID, startDate: startDate)

        let restoredSettings = AppSettings(defaults: defaults)
        XCTAssertTrue(restoredSettings.isDismissed(alertID: alertID))
        XCTAssertTrue(restoredSettings.isDismissed(alertID: "different-id", startDate: startDate))
    }

    @MainActor
    func testPrunesDismissedAlertsOlderThanOneDay() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let oldStartDate = now.addingTimeInterval(-24 * 60 * 60 - 1)
        let recentStartDate = now.addingTimeInterval(-24 * 60 * 60 + 1)

        settings.dismiss(alertID: "old-event-1799913599", startDate: oldStartDate)
        settings.dismiss(alertID: "recent-event-1799913601", startDate: recentStartDate)
        settings.pruneDismissedAlerts(now: now)

        XCTAssertFalse(settings.isDismissed(alertID: "old-event-1799913599"))
        XCTAssertFalse(settings.isDismissed(alertID: "different-id", startDate: oldStartDate))
        XCTAssertTrue(settings.isDismissed(alertID: "recent-event-1799913601"))
        XCTAssertTrue(settings.isDismissed(alertID: "different-id", startDate: recentStartDate))
    }

    @MainActor
    func testPruningRemovesDismissedAlertsWithMalformedIDs() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(["invalid-alert-id"], forKey: "dismissedAlertIDs")

        let settings = AppSettings(defaults: defaults)
        settings.pruneDismissedAlerts(now: Date(timeIntervalSince1970: 1_800_000_000))

        XCTAssertFalse(settings.isDismissed(alertID: "invalid-alert-id"))
    }

    @MainActor
    func testDisabledCalendarPersistsAndNewCalendarsAreEnabled() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)

        XCTAssertTrue(settings.isCalendarEnabled(calendarIdentifier: "new-calendar"))

        settings.setCalendarEnabled(
            false,
            calendarIdentifier: "work-calendar",
            availableCalendarIdentifiers: ["work-calendar", "personal-calendar"]
        )

        let restoredSettings = AppSettings(defaults: defaults)
        XCTAssertFalse(restoredSettings.isCalendarEnabled(calendarIdentifier: "work-calendar"))

        restoredSettings.setCalendarEnabled(
            true,
            calendarIdentifier: "work-calendar",
            availableCalendarIdentifiers: ["work-calendar", "personal-calendar"]
        )
        XCTAssertTrue(AppSettings(defaults: defaults).isCalendarEnabled(calendarIdentifier: "work-calendar"))
    }

    @MainActor
    func testKeepsOneCalendarEnabled() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        let calendarIdentifiers = Set(["work-calendar", "personal-calendar"])

        settings.setCalendarEnabled(
            false,
            calendarIdentifier: "work-calendar",
            availableCalendarIdentifiers: calendarIdentifiers
        )
        settings.setCalendarEnabled(
            false,
            calendarIdentifier: "personal-calendar",
            availableCalendarIdentifiers: calendarIdentifiers
        )

        XCTAssertFalse(settings.isCalendarEnabled(calendarIdentifier: "work-calendar"))
        XCTAssertTrue(settings.isCalendarEnabled(calendarIdentifier: "personal-calendar"))
    }

    @MainActor
    func testRestoresCalendarsWhenEveryAvailableCalendarIsDisabled() {
        let (suiteName, defaults) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let calendarIdentifiers = Set(["work-calendar", "personal-calendar"])
        defaults.set(Array(calendarIdentifiers), forKey: "disabledCalendarIdentifiers")

        let settings = AppSettings(defaults: defaults)
        settings.restoreCalendarSelectionIfAllDisabled(
            availableCalendarIdentifiers: calendarIdentifiers
        )

        XCTAssertTrue(settings.isCalendarEnabled(calendarIdentifier: "work-calendar"))
        XCTAssertTrue(settings.isCalendarEnabled(calendarIdentifier: "personal-calendar"))
    }

    private func makeDefaults() -> (suiteName: String, defaults: UserDefaults) {
        let suiteName = "JoinNowTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (suiteName, defaults)
    }
}

@MainActor
private final class MockLaunchAtLoginService: LaunchAtLoginManaging {
    enum Error: Swift.Error {
        case updateFailed
    }

    var isEnabled: Bool
    var error: Error?

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if let error {
            throw error
        }

        isEnabled = enabled
    }
}
