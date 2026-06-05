import SwiftUI

struct SettingsView: View {
    private enum Layout {
        static let contentWidth: CGFloat = 600
        static let labelWidth: CGFloat = 220
    }

    @ObservedObject var settings: AppSettings

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 24, verticalSpacing: 16) {
            settingsRow("Enable JoinNow") {
                Toggle("", isOn: enabledBinding)
                    .labelsHidden()
            }

            settingsRow("Show alert before event") {
                Picker("", selection: leadTimeBinding) {
                    ForEach(AppSettings.allowedLeadTimes, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            settingsRow("Only show events with meeting links") {
                Toggle("", isOn: onlyMeetingLinksBinding)
                    .labelsHidden()
            }

            settingsRow("Alert background opacity") {
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

            settingsRow("Alert window color") {
                ColorPicker("", selection: alertBackgroundColorBinding, supportsOpacity: false)
                    .labelsHidden()
            }

            settingsRow("Alert text color") {
                ColorPicker("", selection: alertTextColorBinding, supportsOpacity: false)
                    .labelsHidden()
            }
        }
        .padding(24)
        .frame(minWidth: Layout.contentWidth, idealWidth: Layout.contentWidth)
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
