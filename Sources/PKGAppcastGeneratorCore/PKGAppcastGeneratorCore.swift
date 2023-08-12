import Foundation
import XMLCoder

public enum PKGAppcastGeneratorCore {
	private static let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss ZZ"
		return formatter
	}()

	public static func asdf() throws {
		let item = AppcastItem(
			title: "Version 1.0",
			link: URL(string: "https://google.com")!,
			version: "1234",
			shortVersionString: "1.0.0",
			description: "<p class='header'>this is something</p>",
			publishedDate: Date(),
			enclosure: AppcastItem.Enclosure(
				url: URL(string: "https://foo.com/example.pkg")!,
				length: 500,
				type: "application/octet-stream",
				edSignature: "asdf",
				installationType: "package"))

		let channel = AppcastChannel(
			title: "App Changelog",
			link: URL(string: "https://google.com")!,
			description: "Most recent changes",
			language: "en",
			items: [item])

		let appCast = Appcast(channels: [channel])

		let encoder = XMLEncoder()
		encoder.dateEncodingStrategy = .formatted(Self.dateFormatter)
		encoder.outputFormatting = .prettyPrinted

		let data = try encoder.encode(
			appCast,
			withRootKey: "rss",
			rootAttributes: [
				"version": "2.0",
				"xmlns:sparkle": "http://www.andymatuschak.org/xml-namespaces/sparkle",
				"xmlns:dc": "http://purl.org/dc/elements/1.1/",
			],
			header: XMLHeader(version: 1.0, encoding: "utf-8"),
			doctype: nil)

		print(String(data: data, encoding: .utf8)!)
	}
}
