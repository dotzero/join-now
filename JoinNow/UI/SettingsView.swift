import SwiftUI

struct SettingsView: View {
    private enum Layout {
        static let contentWidth: CGFloat = 600
        static let labelWidth: CGFloat = 220
    }

    @ObservedObject var settings: AppSettings
    let onPreview: () -> Void

    var body: some View {
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

            Button("Preview", action: onPreview)
                .keyboardShortcut("p")
                .frame(maxWidth: .infinity, alignment: .trailing)
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
