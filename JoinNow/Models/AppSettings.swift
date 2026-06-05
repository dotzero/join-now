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

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Key.isEnabled) }
    }

    @Published var leadTimeMinutes: Int {
        didSet {
            let value = Self.allowedLeadTimes.contains(leadTimeMinutes) ? leadTimeMinutes : 5
            defaults.set(value, forKey: Key.leadTimeMinutes)
            if value != leadTimeMinutes {
                leadTimeMinutes = value
            }
        }
    }

    @Published var onlyEventsWithMeetingLink: Bool {
        didSet { defaults.set(onlyEventsWithMeetingLink, forKey: Key.onlyEventsWithMeetingLink) }
    }

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
