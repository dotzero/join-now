import SwiftUI

struct MeetingAlertView: View {
    let title: String
    let startDate: Date
    let calendarTitle: String
    let calendarColor: Color
    let meetingURL: URL?
    let onJoin: (URL) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Meeting Starting Soon")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))

                Text(title)
                    .font(.system(size: 72, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.45)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 80)

                HStack(spacing: 18) {
                    Text(startDate, style: .time)
                        .font(.system(size: 34, weight: .semibold))

                    HStack(spacing: 10) {
                        Circle()
                            .fill(calendarColor)
                            .frame(width: 16, height: 16)
                        Text(calendarTitle)
                            .lineLimit(1)
                    }
                    .font(.system(size: 26, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.9))

                HStack(spacing: 16) {
                    if let meetingURL {
                        Button {
                            onJoin(meetingURL)
                        } label: {
                            Text("Join Meeting")
                                .frame(width: 180)
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(AlertPrimaryButtonStyle())
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Text("Dismiss")
                            .frame(width: 140)
                    }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(AlertSecondaryButtonStyle())
                }
                .font(.system(size: 22, weight: .semibold))
                .padding(.top, 18)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(48)
        }
    }
}

private struct AlertPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 18)
            .background(configuration.isPressed ? Color.white.opacity(0.75) : Color.white)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct AlertSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 18)
            .background(configuration.isPressed ? Color.white.opacity(0.18) : Color.white.opacity(0.12))
            .foregroundStyle(.white)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
