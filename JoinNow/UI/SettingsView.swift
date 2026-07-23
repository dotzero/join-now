import SwiftUI

struct SettingsView: View {
    private enum Layout {
        static let contentWidth: CGFloat = 600
        static let labelWidth: CGFloat = 220
        static let calendarListWidth: CGFloat = 360
        static let calendarListHeight: CGFloat = 240
    }

    @ObservedObject var settings: AppSettings
    let calendarService: CalendarEventFetching
    let onPreview: () -> Void
    @State private var calendars = [CalendarInfo]()
    @State private var hasLoadedCalendars = false

    var body: some View {
        TabView {
            generalSettings
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .tabItem { Text("General") }

            calendarsSettings
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .tabItem { Text("Calendars") }
        }
        .frame(minWidth: Layout.contentWidth, idealWidth: Layout.contentWidth, minHeight: 400)
        .task {
            calendars = await calendarService.calendars()
            hasLoadedCalendars = true
        }
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 22) {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 24, verticalSpacing: 16) {
                settingsRow("Enabled") {
                    Toggle("", isOn: enabledBinding)
                        .labelsHidden()
                }

                settingsRow("Launch automatically at startup") {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("", isOn: launchAtStartupBinding)
                            .labelsHidden()

                        if let errorMessage = settings.launchAtStartupErrorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                settingsRow("Alert lead time") {
                    Picker("", selection: leadTimeBinding) {
                        ForEach(AppSettings.allowedLeadTimes, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                settingsRow("Events with links only") {
                    Toggle("", isOn: onlyMeetingLinksBinding)
                        .labelsHidden()
                }

                settingsRow("Alert sound") {
                    Picker("", selection: alertSoundBinding) {
                        ForEach(AlertSound.allCases) { sound in
                            Text(sound.displayName).tag(sound)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                settingsRow("Background opacity") {
                    HStack(spacing: 12) {
                        Slider(
                            value: alertBackgroundOpacityBinding,
                            in: 0 ... 100,
                            step: 1
                        )

                        Text("\(Int(settings.alertBackgroundOpacityPercent.rounded()))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                }

                settingsRow("Background color") {
                    ColorPicker("", selection: alertBackgroundColorBinding, supportsOpacity: false)
                        .labelsHidden()
                }

                settingsRow("Text color") {
                    ColorPicker("", selection: alertTextColorBinding, supportsOpacity: false)
                        .labelsHidden()
                }
            }

            Divider()

            HStack {
                Text(appVersionLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Preview", action: onPreview)
                    .keyboardShortcut("p")
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .padding(.top, 24)
    }

    private var calendarsSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose the calendars JoinNow should use for reminders.\nEvents from unchecked calendars are ignored.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Group {
                if !hasLoadedCalendars {
                    ProgressView()
                } else if calendars.isEmpty {
                    Text("No calendars are available.")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(calendars) { calendar in
                                Toggle(calendar.title, isOn: calendarEnabledBinding(for: calendar.id))
                                    .toggleStyle(.checkbox)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: Layout.calendarListHeight)
                }
            }
            .frame(width: Layout.calendarListWidth, alignment: .leading)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .padding(.top, 24)
    }

    private func settingsRow(
        _ title: String,
        @ViewBuilder control: () -> some View
    ) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.primary)
                .frame(width: Layout.labelWidth, alignment: .leading)

            control()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { settings.isEnabled },
            set: { settings.setEnabled($0) }
        )
    }

    private func calendarEnabledBinding(for calendarIdentifier: String) -> Binding<Bool> {
        Binding(
            get: { settings.isCalendarEnabled(calendarIdentifier: calendarIdentifier) },
            set: { settings.setCalendarEnabled($0, calendarIdentifier: calendarIdentifier) }
        )
    }

    private var launchAtStartupBinding: Binding<Bool> {
        Binding(
            get: { settings.launchAtStartupEnabled },
            set: { settings.setLaunchAtStartupEnabled($0) }
        )
    }

    private var leadTimeBinding: Binding<Int> {
        Binding(
            get: { settings.leadTimeMinutes },
            set: { settings.setLeadTimeMinutes($0) }
        )
    }

    private var onlyMeetingLinksBinding: Binding<Bool> {
        Binding(
            get: { settings.onlyEventsWithMeetingLink },
            set: { settings.setOnlyEventsWithMeetingLink($0) }
        )
    }

    private var alertSoundBinding: Binding<AlertSound> {
        Binding(
            get: { settings.alertSound },
            set: { settings.setAlertSound($0) }
        )
    }

    private var alertBackgroundOpacityBinding: Binding<Double> {
        Binding(
            get: { settings.alertBackgroundOpacityPercent },
            set: { settings.setAlertBackgroundOpacityPercent($0) }
        )
    }

    private var alertBackgroundColorBinding: Binding<Color> {
        Binding(
            get: { settings.alertBackgroundColor },
            set: { settings.setAlertBackgroundColor($0) }
        )
    }

    private var alertTextColorBinding: Binding<Color> {
        Binding(
            get: { settings.alertTextColor },
            set: { settings.setAlertTextColor($0) }
        )
    }

    private var appVersionLabel: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

        switch shortVersion {
        case let shortVersion?:
            return "Version \(shortVersion)"
        default:
            return "Version n/a"
        }
    }
}
