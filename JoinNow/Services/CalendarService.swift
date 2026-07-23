import EventKit
import Foundation

@MainActor
protocol CalendarEventFetching: AnyObject {
    func events(from startDate: Date, to endDate: Date) async -> [EKEvent]
    func calendars() async -> [CalendarInfo]
}

struct CalendarInfo: Identifiable, Equatable {
    let id: String
    let title: String
}

@MainActor
final class CalendarService: CalendarEventFetching {
    private let eventStore = EKEventStore()

    /// Calendar privacy is controlled by macOS System Settings. Sandboxed builds also
    /// require com.apple.security.personal-information.calendars in JoinNow.entitlements.
    func requestAccessIfNeeded() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .authorized, .fullAccess:
            return true
        case .notDetermined:
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                return false
            }
        case .denied, .restricted, .writeOnly:
            return false
        @unknown default:
            return false
        }
    }

    func events(from startDate: Date, to endDate: Date) async -> [EKEvent] {
        guard await requestAccessIfNeeded() else {
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        return eventStore.events(matching: predicate)
    }

    func calendars() async -> [CalendarInfo] {
        guard await requestAccessIfNeeded() else {
            return []
        }

        return eventStore.calendars(for: .event)
            .map { CalendarInfo(id: $0.calendarIdentifier, title: $0.title) }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}
