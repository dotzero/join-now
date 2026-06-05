import EventKit
import Foundation

struct MeetingLinkExtractor {
    private let patterns: [String] = [
        #"https?://[^\s<>"']*zoom\.us/[^\s<>"']*"#,
        #"https?://meet\.google\.com/[^\s<>"']*"#,
        #"https?://[^\s<>"']*teams\.microsoft\.com/[^\s<>"']*"#,
        #"https?://teams\.live\.com/[^\s<>"']*"#,
        #"https?://[^\s<>"']*\.ktalk\.ru/[^\s<>"']*"#,
        #"https?://aka\.ms/[^\s<>"']*"#
    ]

    func firstMeetingLink(in event: EKEvent) -> URL? {
        let fields = [
            event.title,
            event.notes,
            event.location,
            event.url?.absoluteString
        ].compactMap(\.self)

        for field in fields {
            if let url = firstMeetingLink(in: field) {
                return url
            }
        }

        return nil
    }

    func firstMeetingLink(in text: String) -> URL? {
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }

            let range = NSRange(text.startIndex ..< text.endIndex, in: text)
            guard let match = regex.firstMatch(in: text, range: range),
                  let matchRange = Range(match.range, in: text)
            else {
                continue
            }

            let rawURL = String(text[matchRange])
                .trimmingCharacters(in: CharacterSet(charactersIn: ".,);]}>\"'"))

            if let url = URL(string: rawURL) {
                return url
            }
        }

        return nil
    }
}
