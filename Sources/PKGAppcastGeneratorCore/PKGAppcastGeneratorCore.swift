import Foundation
import XMLCoder

public enum PKGAppcastGeneratorCore {
	private static let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss ZZ"
		return formatter
	}()

	public static func printSampleAppcast() throws {
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
				edSignature: "pretendSignature",
				installationType: "package"))


		let channel = AppcastChannel(
			title: "App Changelog",
			items: [item])

		let appCast = Appcast(channel: channel)

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

	public static func generateAppcast(
		fromContentsOfDirectory contentsOfDirectory: URL,
		previousAppcastData: Data?,
		channelTitle: String,
		signatureGenerator: (URL) throws -> String?,
		downloadURLPrefix: URL) throws -> Data {

			let directoryContents = try FileManager.default.contentsOfDirectory(at: contentsOfDirectory, includingPropertiesForKeys: nil)
			let jsonFiles = directoryContents.filter { $0.pathExtension.lowercased() == "json" }

			guard jsonFiles.isEmpty == false else {
				throw CustomError(message: "No json files to get data from")
			}

			let allowedExtensions = [
				"pkg",
				"mpkg",
				"zip",
				"dmg"
			]
			let pkgFiles: [URL] = try jsonFiles
				.map { jsonURL in
					for ext in allowedExtensions {
						let url = jsonURL
							.deletingPathExtension()
							.appendingPathExtension(ext)
						guard
							(try? url.checkResourceIsReachable()) == true
						else { continue }
						return url
					}
					throw CustomError(message: "No valid package for \(jsonURL.lastPathComponent)")
				}

			var appCast: Appcast
			if let previousAppcastData {
				let decoder = XMLDecoder()
				decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)

				appCast = try decoder.decode(Appcast.self, from: previousAppcastData)
			} else {
				appCast = Appcast(channel: AppcastChannel(title: channelTitle, items: []))
			}

			let jsonDecoder = JSONDecoder()
			let items = try zip(jsonFiles, pkgFiles)
				.map {
					let jsonFile = $0.0
					let pkgFile = $0.1

					let jsonData = try Data(contentsOf: jsonFile)
					let jsonItem = try jsonDecoder.decode(JSONAppcastItem.self, from: jsonData)

					guard
						let fileSize = try pkgFile.resourceValues(forKeys: [.fileSizeKey]).fileSize
					else { throw CustomError(message: "Cannot retrieve file size for \(pkgFile.lastPathComponent).") }

					let enclosure = AppcastItem.Enclosure(
						url: downloadURLPrefix.appending(component: pkgFile.lastPathComponent),
						length: fileSize,
						type: "application/octet-stream",
						edSignature: try signatureGenerator(pkgFile),
						installationType: pkgFile.pathExtension.contains("pkg") ? "package" : nil)
					return AppcastItem(from: jsonItem, enclosure: enclosure)
				}

			appCast.channel.title = channelTitle
			appCast.channel.items = items

			let encoder = XMLEncoder()
			encoder.dateEncodingStrategy = .formatted(Self.dateFormatter)
			encoder.outputFormatting = .prettyPrinted

			return try encoder.encode(
				appCast,
				withRootKey: "rss",
				rootAttributes: [
					"version": "2.0",
					"xmlns:sparkle": "http://www.andymatuschak.org/xml-namespaces/sparkle",
					"xmlns:dc": "http://purl.org/dc/elements/1.1/",
				],
				header: XMLHeader(version: 1.0, encoding: "utf-8"),
				doctype: nil)
		}
}
