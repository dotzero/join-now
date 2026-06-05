import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Toggle("Enable JoinNow", isOn: enabledBinding)

            Picker("Show alert before event", selection: leadTimeBinding) {
                ForEach(AppSettings.allowedLeadTimes, id: \.self) { minutes in
                    Text("\(minutes) min").tag(minutes)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Only show events with meeting links", isOn: onlyMeetingLinksBinding)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Alert background opacity")
                    Spacer()
                    Text("\(Int(settings.alertBackgroundOpacityPercent.rounded()))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: alertBackgroundOpacityBinding,
                    in: 0 ... 100,
                    step: 1
                )
            }

            ColorPicker("Alert window color", selection: alertBackgroundColorBinding, supportsOpacity: false)

            ColorPicker("Alert text color", selection: alertTextColorBinding, supportsOpacity: false)
        }
        .padding(24)
        .frame(width: 420)
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { settings.isEnabled },
            set: { settings.setEnabled($0) }
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
}
