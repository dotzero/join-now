import EventKit
@testable import JoinNow
import XCTest

final class MeetingLinkExtractorTests: XCTestCase {
    private let extractor = MeetingLinkExtractor()

    func testExtractsGoogleMeetLinkFromNotes() {
        let url = extractor.firstMeetingLink(in: "Join here: https://meet.google.com/abc-defg-hij")

        XCTAssertEqual(url?.absoluteString, "https://meet.google.com/abc-defg-hij")
    }

    func testExtractsZoomLinkCaseInsensitively() {
        let url = extractor.firstMeetingLink(in: "Zoom: HTTPS://ACME.ZOOM.US/j/123456789")

        XCTAssertEqual(url?.host?.lowercased(), "acme.zoom.us")
        XCTAssertEqual(url?.path, "/j/123456789")
    }

    func testTrimsTrailingPunctuation() {
        let url = extractor.firstMeetingLink(in: "Meeting (https://teams.microsoft.com/l/meetup-join/abc),")

        XCTAssertEqual(url?.absoluteString, "https://teams.microsoft.com/l/meetup-join/abc")
    }

    func testExtractsKtalkLink() {
        let url = extractor.firstMeetingLink(
            in: "Talk: https://acme.ktalk.ru/qwerty"
        )

        XCTAssertEqual(url?.host, "acme.ktalk.ru")
        XCTAssertEqual(url?.path, "/qwerty")
    }

    func testExtractsYandexTelemost360Link() {
        let url = extractor.firstMeetingLink(
            in: "Telemost: https://telemost.360.yandex.ru/j/123456789"
        )

        XCTAssertEqual(url?.host, "telemost.360.yandex.ru")
        XCTAssertEqual(url?.path, "/j/123456789")
    }

    func testPrefersLocationLinkOverNotesLinkInEvent() {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.location = "Room: https://telemost.360.yandex.ru/j/123456789"
        event.notes = "Notes: https://meet.google.com/abc-defg-hij"

        let url = extractor.firstMeetingLink(in: event)

        XCTAssertEqual(url?.absoluteString, "https://telemost.360.yandex.ru/j/123456789")
    }

    func testPrefersFirstSupportedProviderOrder() {
        let url = extractor.firstMeetingLink(
            in: "meet https://meet.google.com/abc-defg-hij zoom https://example.zoom.us/j/123"
        )

        XCTAssertEqual(url?.absoluteString, "https://example.zoom.us/j/123")
    }

    func testReturnsNilWhenTextHasNoSupportedMeetingLink() {
        let url = extractor.firstMeetingLink(in: "No video call link here: https://example.com")

        XCTAssertNil(url)
    }
}
