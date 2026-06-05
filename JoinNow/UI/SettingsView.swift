import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Toggle("Enable JoinNow", isOn: $settings.isEnabled)

            Picker("Show alert before event", selection: $settings.leadTimeMinutes) {
                ForEach(AppSettings.allowedLeadTimes, id: \.self) { minutes in
                    Text("\(minutes) min").tag(minutes)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Only show events with meeting links", isOn: $settings.onlyEventsWithMeetingLink)
        }
        .padding(24)
        .frame(width: 420)
    }
}
