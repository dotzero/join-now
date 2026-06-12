import SwiftUI

struct MeetingAlertView: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let startDate: Date
    let calendarTitle: String
    let calendarColor: Color
    let meetingURL: URL?
    let talkAppURL: URL?
    let backgroundColor: Color
    let backgroundOpacityPercent: Double
    let textColor: Color
    let onJoin: (URL) -> Void
    let onOpenTalk: (URL) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            backgroundColor
                .opacity(backgroundOpacityPercent / 100)
                .ignoresSafeArea()

            VStack(spacing: 34) {
                VStack(spacing: 18) {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text("Meeting Starting \(startOffsetLabel(now: context.date))")
                            .font(.system(size: 22, weight: .semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(textColor.opacity(0.72))
                    }

                    Text(title)
                        .font(.system(size: 76, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.42)
                        .foregroundStyle(textColor)
                        .padding(.horizontal, 72)
                }

                HStack(spacing: 18) {
                    Text(startDate, style: .time)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()

                    HStack(spacing: 10) {
                        Circle()
                            .fill(calendarColor)
                            .frame(width: 16, height: 16)
                        Text(calendarTitle)
                            .lineLimit(1)
                    }
                    .font(.system(size: 25, weight: .medium, design: .rounded))
                }
                .foregroundStyle(textColor.opacity(0.86))

                HStack(spacing: 18) {
                    if let meetingURL {
                        Button {
                            onJoin(meetingURL)
                        } label: {
                            Label("Join Meeting", systemImage: "video.fill")
                                .frame(width: 260)
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(AlertPrimaryButtonStyle(colorScheme: colorScheme))
                        .focusable(false)
                    } else if let talkAppURL {
                        Button {
                            onOpenTalk(talkAppURL)
                        } label: {
                            Label("Open Talk", systemImage: "bubble.left.and.bubble.right.fill")
                                .frame(width: 240)
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(AlertPrimaryButtonStyle(colorScheme: colorScheme))
                        .focusable(false)
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Label("Dismiss", systemImage: "xmark")
                            .frame(width: 150)
                    }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(AlertSecondaryButtonStyle(colorScheme: colorScheme))
                    .focusable(false)
                }
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(48)
        }
    }

    private func startOffsetLabel(now: Date) -> String {
        let secondsUntilStart = startDate.timeIntervalSince(now)

        guard secondsUntilStart > 0 else {
            return "now"
        }

        let minutesUntilStart = max(1, Int(ceil(secondsUntilStart / 60)))
        return "in \(minutesUntilStart) min"
    }
}

private struct AlertPrimaryButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 22)
            .background(primaryBackground(isPressed: configuration.isPressed))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.42 : 0.24), radius: 28, y: 14)
    }

    private func primaryBackground(isPressed: Bool) -> Color {
        if isPressed {
            return Color.accentColor.opacity(0.78)
        }

        return Color.accentColor
    }
}

private struct AlertSecondaryButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 22)
            .background(.regularMaterial)
            .foregroundStyle(foregroundColor)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor.opacity(configuration.isPressed ? 0.68 : 0.42), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var foregroundColor: Color {
        colorScheme == .dark ? .white : Color(nsColor: .labelColor)
    }

    private var borderColor: Color {
        colorScheme == .dark ? .white : .black
    }
}
