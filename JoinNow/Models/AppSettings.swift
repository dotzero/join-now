import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let isEnabled = "isEnabled"
        static let leadTimeMinutes = "leadTimeMinutes"
        static let onlyEventsWithMeetingLink = "onlyEventsWithMeetingLink"
        static let dismissedAlertIDs = "dismissedAlertIDs"
    }

    static let allowedLeadTimes = [1, 3, 5, 10, 15]

    @Published private(set) var isEnabled: Bool

    @Published private(set) var leadTimeMinutes: Int

    @Published private(set) var onlyEventsWithMeetingLink: Bool

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Key.isEnabled) == nil {
            defaults.set(true, forKey: Key.isEnabled)
        }

        let storedLeadTime = defaults.integer(forKey: Key.leadTimeMinutes)
        self.isEnabled = defaults.bool(forKey: Key.isEnabled)
        self.leadTimeMinutes = Self.allowedLeadTimes.contains(storedLeadTime) ? storedLeadTime : 5
        self.onlyEventsWithMeetingLink = defaults.bool(forKey: Key.onlyEventsWithMeetingLink)
    }

    func setEnabled(_ value: Bool) {
        guard isEnabled != value else {
            return
        }

        isEnabled = value
        defaults.set(value, forKey: Key.isEnabled)
    }

    func setLeadTimeMinutes(_ value: Int) {
        let normalizedValue = Self.allowedLeadTimes.contains(value) ? value : 5
        guard leadTimeMinutes != normalizedValue else {
            return
        }

        leadTimeMinutes = normalizedValue
        defaults.set(normalizedValue, forKey: Key.leadTimeMinutes)
    }

    func setOnlyEventsWithMeetingLink(_ value: Bool) {
        guard onlyEventsWithMeetingLink != value else {
            return
        }

        onlyEventsWithMeetingLink = value
        defaults.set(value, forKey: Key.onlyEventsWithMeetingLink)
    }

    func isDismissed(alertID: String) -> Bool {
        dismissedAlertIDs.contains(alertID)
    }

    func dismiss(alertID: String) {
        var ids = dismissedAlertIDs
        ids.insert(alertID)
        defaults.set(Array(ids), forKey: Key.dismissedAlertIDs)
    }

    private var dismissedAlertIDs: Set<String> {
        Set(defaults.stringArray(forKey: Key.dismissedAlertIDs) ?? [])
    }
}
