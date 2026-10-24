import SwiftUI

struct SettingsView: View {
    private enum Layout {
        static let contentWidth: CGFloat = 560
        static let contentHeight: CGFloat = 440
    }

    @ObservedObject var settings: AppSettings
    let calendarService: CalendarEventFetching
    let onPreview: () -> Void
    var onPaneChange: (String) -> Void = { _ in }
    @AppStorage("selectedSettingsPane") private var selectedPane = "general"
    @State private var calendars = [CalendarInfo]()
    @State private var hasLoadedCalendars = false

    var body: some View {
        TabView(selection: $selectedPane) {
            generalSettings
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag("general")

            appearanceSettings
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
                .tag("appearance")

            calendarsSettings
                .tabItem { Label("Calendars", systemImage: "calendar") }
                .tag("calendars")
        }
        .frame(width: Layout.contentWidth, height: Layout.contentHeight)
        .onChange(of: selectedPane, initial: true) { _, pane in
            onPaneChange(pane.capitalized)
        }
        .task {
            calendars = await calendarService.calendars()
            settings.restoreCalendarSelectionIfAllDisabled(
                availableCalendarIdentifiers: Set(calendars.map(\.id))
            )
            hasLoadedCalendars = true
        }
    }

    private var generalSettings: some View {
        Form {
            Section("Reminders") {
                Toggle("Enable reminders", isOn: enabledBinding)
                    .toggleStyle(.switch)

                Picker("Alert before event", selection: leadTimeBinding) {
                    ForEach(AppSettings.allowedLeadTimes, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Only events with meeting links", isOn: onlyMeetingLinksBinding)
                    .toggleStyle(.checkbox)

                Picker("Alert sound", selection: alertSoundBinding) {
                    ForEach(AlertSound.allCases) { sound in
                        Text(sound.displayName).tag(sound)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Startup") {
                Toggle("Open at login", isOn: launchAtStartupBinding)
                    .toggleStyle(.checkbox)

                if let errorMessage = settings.launchAtStartupErrorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Text(appVersionLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private var appearanceSettings: some View {
        Form {
            Section("Alert window") {
                LabeledContent("Background opacity") {
                    HStack(spacing: 12) {
                        Slider(
                            value: alertBackgroundOpacityBinding,
                            in: AppSettings.minimumAlertBackgroundOpacityPercent ... 100,
                            step: 1
                        ) {
                            Text("Background opacity")
                        }
                        .labelsHidden()

                        Text("\(Int(settings.alertBackgroundOpacityPercent.rounded()))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                }

                ColorPicker("Background color", selection: alertBackgroundColorBinding, supportsOpacity: false)
                ColorPicker("Text color", selection: alertTextColorBinding, supportsOpacity: false)
            }

            Button("Preview Alert", action: onPreview)
                .keyboardShortcut("p")
        }
        .formStyle(.grouped)
    }

    private var calendarsSettings: some View {
        Form {
            Section {
                if !hasLoadedCalendars {
                    ProgressView("Loading calendars…")
                } else if calendars.isEmpty {
                    Text("No calendars are available.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(calendars) { calendar in
                        Toggle(calendar.title, isOn: calendarEnabledBinding(for: calendar.id))
                            .toggleStyle(.checkbox)
                            .disabled(enabledCalendarCount == 1 && settings
                                .isCalendarEnabled(calendarIdentifier: calendar.id))
                    }
                }
            } header: {
                Text("Calendars")
            } footer: {
                Text("Choose the calendars JoinNow uses for reminders. At least one calendar must stay selected.")
            }
        }
        .formStyle(.grouped)
    }

    private var enabledCalendarCount: Int {
        calendars.filter { settings.isCalendarEnabled(calendarIdentifier: $0.id) }.count
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
            set: {
                settings.setCalendarEnabled(
                    $0,
                    calendarIdentifier: calendarIdentifier,
                    availableCalendarIdentifiers: Set(calendars.map(\.id))
                )
            }
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
