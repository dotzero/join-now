import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let isEnabled = "isEnabled"
        static let leadTimeMinutes = "leadTimeMinutes"
        static let onlyEventsWithMeetingLink = "onlyEventsWithMeetingLink"
        static let alertSound = "alertSound"
        static let alertBackgroundOpacityPercent = "alertBackgroundOpacityPercent"
        static let alertBackgroundColor = "alertBackgroundColor"
        static let alertTextColor = "alertTextColor"
        static let dismissedAlertIDs = "dismissedAlertIDs"
        static let dismissedAlertStartTimestamps = "dismissedAlertStartTimestamps"
        static let disabledCalendarIdentifiers = "disabledCalendarIdentifiers"
    }

    static let allowedLeadTimes = [1, 3, 5, 10, 15]
    static let defaultAlertBackgroundOpacityPercent = 80.0
    static let defaultAlertBackgroundColor = Color.black
    static let defaultAlertTextColor = Color.white
    static let defaultAlertSound = AlertSound.hero

    @Published private(set) var isEnabled: Bool

    @Published private(set) var leadTimeMinutes: Int

    @Published private(set) var onlyEventsWithMeetingLink: Bool

    @Published private(set) var launchAtStartupEnabled: Bool

    @Published private(set) var launchAtStartupErrorMessage: String?

    @Published private(set) var alertSound: AlertSound

    @Published private(set) var alertBackgroundOpacityPercent: Double

    @Published private(set) var alertBackgroundColor: Color

    @Published private(set) var alertTextColor: Color

    @Published private(set) var disabledCalendarIdentifiers: Set<String>

    private let defaults: UserDefaults
    private let launchAtLoginService: LaunchAtLoginManaging

    init(
        defaults: UserDefaults = .standard,
        launchAtLoginService: LaunchAtLoginManaging = LaunchAtLoginService()
    ) {
        self.defaults = defaults
        self.launchAtLoginService = launchAtLoginService

        if defaults.object(forKey: Key.isEnabled) == nil {
            defaults.set(true, forKey: Key.isEnabled)
        }

        let storedLeadTime = defaults.integer(forKey: Key.leadTimeMinutes)
        self.isEnabled = defaults.bool(forKey: Key.isEnabled)
        self.leadTimeMinutes = Self.allowedLeadTimes.contains(storedLeadTime) ? storedLeadTime : 5
        self.onlyEventsWithMeetingLink = defaults.bool(forKey: Key.onlyEventsWithMeetingLink)
        self.launchAtStartupEnabled = launchAtLoginService.isEnabled
        self.alertSound = Self.alertSound(for: defaults.string(forKey: Key.alertSound))
        if defaults.object(forKey: Key.alertBackgroundOpacityPercent) == nil {
            self.alertBackgroundOpacityPercent = Self.defaultAlertBackgroundOpacityPercent
        } else {
            self.alertBackgroundOpacityPercent = Self.normalizedAlertBackgroundOpacityPercent(
                defaults.double(forKey: Key.alertBackgroundOpacityPercent)
            )
        }
        self.alertBackgroundColor = Self.color(
            forKey: Key.alertBackgroundColor,
            defaultValue: Self.defaultAlertBackgroundColor,
            defaults: defaults
        )
        self.alertTextColor = Self.color(
            forKey: Key.alertTextColor,
            defaultValue: Self.defaultAlertTextColor,
            defaults: defaults
        )
        self.disabledCalendarIdentifiers = Set(
            defaults.stringArray(forKey: Key.disabledCalendarIdentifiers) ?? []
        )
    }

    func setEnabled(_ value: Bool) {
        guard isEnabled != value else {
            return
        }

        isEnabled = value
        defaults.set(value, forKey: Key.isEnabled)
    }

    func setLaunchAtStartupEnabled(_ value: Bool) {
        guard launchAtStartupEnabled != value else {
            return
        }

        do {
            try launchAtLoginService.setEnabled(value)
            launchAtStartupEnabled = launchAtLoginService.isEnabled
            launchAtStartupErrorMessage = nil
        } catch {
            launchAtStartupEnabled = launchAtLoginService.isEnabled
            launchAtStartupErrorMessage = error.localizedDescription
        }
    }

    func refreshLaunchAtStartupEnabled() {
        launchAtStartupEnabled = launchAtLoginService.isEnabled
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

    func isCalendarEnabled(calendarIdentifier: String) -> Bool {
        !disabledCalendarIdentifiers.contains(calendarIdentifier)
    }

    func setCalendarEnabled(
        _ enabled: Bool,
        calendarIdentifier: String,
        availableCalendarIdentifiers: Set<String>
    ) {
        guard isCalendarEnabled(calendarIdentifier: calendarIdentifier) != enabled else {
            return
        }

        if !enabled {
            let enabledCalendarIdentifiers = availableCalendarIdentifiers
                .subtracting(disabledCalendarIdentifiers)
            guard enabledCalendarIdentifiers.count > 1 else {
                return
            }
        }

        if enabled {
            disabledCalendarIdentifiers.remove(calendarIdentifier)
        } else {
            disabledCalendarIdentifiers.insert(calendarIdentifier)
        }

        defaults.set(Array(disabledCalendarIdentifiers), forKey: Key.disabledCalendarIdentifiers)
    }

    func restoreCalendarSelectionIfAllDisabled(availableCalendarIdentifiers: Set<String>) {
        guard !availableCalendarIdentifiers.isEmpty,
              availableCalendarIdentifiers.isSubset(of: disabledCalendarIdentifiers)
        else {
            return
        }

        disabledCalendarIdentifiers.subtract(availableCalendarIdentifiers)
        defaults.set(Array(disabledCalendarIdentifiers), forKey: Key.disabledCalendarIdentifiers)
    }

    func setAlertSound(_ value: AlertSound) {
        guard alertSound != value else {
            return
        }

        alertSound = value
        defaults.set(value.rawValue, forKey: Key.alertSound)
    }

    func setAlertBackgroundOpacityPercent(_ value: Double) {
        let normalizedValue = Self.normalizedAlertBackgroundOpacityPercent(value)
        guard alertBackgroundOpacityPercent != normalizedValue else {
            return
        }

        alertBackgroundOpacityPercent = normalizedValue
        defaults.set(normalizedValue, forKey: Key.alertBackgroundOpacityPercent)
    }

    func setAlertBackgroundColor(_ value: Color) {
        alertBackgroundColor = value
        Self.setColor(value, forKey: Key.alertBackgroundColor, defaults: defaults)
    }

    func setAlertTextColor(_ value: Color) {
        alertTextColor = value
        Self.setColor(value, forKey: Key.alertTextColor, defaults: defaults)
    }

    func isDismissed(alertID: String) -> Bool {
        dismissedAlertIDs.contains(alertID)
    }

    func isDismissed(alertID: String, startDate: Date) -> Bool {
        isDismissed(alertID: alertID)
            || dismissedAlertStartTimestamps.contains(Self.alertStartTimestamp(for: startDate))
    }

    func dismiss(alertID: String) {
        var ids = dismissedAlertIDs
        ids.insert(alertID)
        defaults.set(Array(ids), forKey: Key.dismissedAlertIDs)
    }

    func dismiss(alertID: String, startDate: Date) {
        dismiss(alertID: alertID)

        var timestamps = dismissedAlertStartTimestamps
        timestamps.insert(Self.alertStartTimestamp(for: startDate))
        defaults.set(Array(timestamps), forKey: Key.dismissedAlertStartTimestamps)
    }

    private var dismissedAlertIDs: Set<String> {
        Set(defaults.stringArray(forKey: Key.dismissedAlertIDs) ?? [])
    }

    private var dismissedAlertStartTimestamps: Set<Int> {
        Set(defaults.array(forKey: Key.dismissedAlertStartTimestamps) as? [Int] ?? [])
    }

    private static func alertStartTimestamp(for startDate: Date) -> Int {
        Int(startDate.timeIntervalSince1970)
    }

    private static func normalizedAlertBackgroundOpacityPercent(_ value: Double) -> Double {
        min(max(value, 0), 100)
    }

    private static func alertSound(for rawValue: String?) -> AlertSound {
        guard let rawValue,
              let alertSound = AlertSound(rawValue: rawValue)
        else {
            return defaultAlertSound
        }

        return alertSound
    }

    private static func color(forKey key: String, defaultValue: Color, defaults: UserDefaults) -> Color {
        guard let components = defaults.array(forKey: key) as? [Double],
              components.count == 4
        else {
            return defaultValue
        }

        return Color(
            red: min(max(components[0], 0), 1),
            green: min(max(components[1], 0), 1),
            blue: min(max(components[2], 0), 1),
            opacity: min(max(components[3], 0), 1)
        )
    }

    private static func setColor(_ color: Color, forKey key: String, defaults: UserDefaults) {
        guard let color = NSColor(color).usingColorSpace(.deviceRGB) else {
            return
        }

        defaults.set(
            [color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent],
            forKey: key
        )
    }
}

enum AlertSound: String, CaseIterable, Identifiable {
    case none
    case hero
    case glass

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .none:
            "Off"
        case .hero:
            "Hero"
        case .glass:
            "Glass"
        }
    }
}
