import Foundation
import XMLCoder
import SwiftPizzaSnips
import ZIPFoundation

public enum PKGAppcastGeneratorCore {
	package static let dateFormatter: DateFormatter = {
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
				mimeType: "application/octet-stream",
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
		downloadsLink: URL?,
		signatureGenerator: (URL) throws -> String?,
		downloadURLPrefix: URL
	) throws -> Data {

		let directoryContents = try FileManager.default.contentsOfDirectory(at: contentsOfDirectory, includingPropertiesForKeys: nil)
		let jsonFiles = directoryContents.filter { $0.pathExtension.lowercased() == "json" }

		let allowedUpdaterExtensions = Set(
			[
				"pkg",
				"mpkg",
				"zip",
				"dmg"
			])
		let updaterFiles = directoryContents.filter { url in
			allowedUpdaterExtensions.contains(url.pathExtension.lowercased())
		}

		let jsonBasenameSet = Set(jsonFiles.map { $0.deletingPathExtension().lastPathComponent })
		let (jsonUpdaterFiles, embeddedUpdaterFiles) = updaterFiles.reduce(into: ([URL](), [URL]())) {
			let basename = $1.deletingPathExtension().lastPathComponent
			if jsonBasenameSet.contains(basename) {
				$0.0.append($1)
			} else {
				$0.1.append($1)
			}
		}

		guard
			case let embeddedFiletypes = embeddedUpdaterFiles.reduce(into: Set([String]()), {
				$0.insert($1.pathExtension.lowercased())
			}),
			embeddedFiletypes.contains("pkg") == false,
			embeddedFiletypes.contains("mpkg") == false,
			embeddedFiletypes.contains("dmg") == false
		else { throw CustomError(message: "pkg, mpkg, and dmg files all require json companion files.")}

		let jsonItems = try handleJSONFilePairs(
			jsonFiles: jsonFiles,
			jsonPKGFiles: jsonUpdaterFiles,
			downloadURLPrefix: downloadURLPrefix,
			signatureGenerator: signatureGenerator)

		let embeddedInfoItems = try handleEmbeddedInfoItems(
			embeddedUpdaterFiles: embeddedUpdaterFiles,
			downloadsLink: downloadsLink,
			downloadURLPrefix: downloadURLPrefix,
			signatureGenerator: signatureGenerator)

		var appCast: Appcast
		if let previousAppcastData {
			let decoder = XMLDecoder()
			decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)

			appCast = try decoder.decode(Appcast.self, from: previousAppcastData)
		} else {
			appCast = Appcast(channel: AppcastChannel(title: channelTitle, items: []))
		}

		appCast.channel.title = channelTitle
		appCast.channel.appendItems(jsonItems)
		appCast.channel.appendItems(embeddedInfoItems)
		appCast.channel.sortItems(by: AppcastChannel.defaultSortItems)

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

	private static func handleJSONFilePairs(
		jsonFiles: [URL],
		jsonPKGFiles: [URL],
		downloadURLPrefix: URL,
		signatureGenerator: (URL) throws -> String?
	) throws -> [AppcastItem] {
		let jsonDecoder = JSONDecoder()

		guard
			jsonFiles.count == jsonPKGFiles.count
		else { throw CustomError(message: "Mismatch count of update files and their json counterparts.") }

		let pkgFiles = jsonPKGFiles.reduce(into: [String: URL]()) {
			$0[$1.deletingPathExtension().lastPathComponent] = $1
		}

		let items = try jsonFiles.map { jsonFile in
			let pkgFile = try pkgFiles[jsonFile.deletingPathExtension().lastPathComponent].unwrap()

			let jsonData = try Data(contentsOf: jsonFile)
			let jsonItem = try jsonDecoder.decode(JSONAppcastItem.self, from: jsonData)

			guard
				let fileSize = try pkgFile.resourceValues(forKeys: [.fileSizeKey]).fileSize
			else { throw CustomError(message: "Cannot retrieve file size for \(pkgFile.lastPathComponent).") }

			let enclosure = AppcastItem.Enclosure(
				url: downloadURLPrefix.appending(component: pkgFile.lastPathComponent),
				length: fileSize,
				mimeType: "application/octet-stream",
				edSignature: try signatureGenerator(pkgFile),
				installationType: pkgFile.pathExtension.contains("pkg") ? "package" : nil)
			return AppcastItem(from: jsonItem, enclosure: enclosure)
		}
		return items
	}

	private static func handleEmbeddedInfoItems(
		embeddedUpdaterFiles: [URL],
		downloadsLink: URL?,
		downloadURLPrefix: URL,
		signatureGenerator: (URL) throws -> String?
	) throws -> [AppcastItem] {
		guard embeddedUpdaterFiles.isOccupied else { return [] }
		guard let downloadsLink else {
			throw CustomError(message: "With embedded files, you need to provide a downloads link! See help.")
		}

		return try embeddedUpdaterFiles.map {
			switch $0.pathExtension.lowercased() {
			case "zip":
				try handleZipEmbeddedInfoItem(
					zipFile: $0,
					downloadsLink: downloadsLink,
					downloadURLPrefix: downloadURLPrefix,
					signatureGenerator: signatureGenerator)
			default:
				throw CustomError(message: "Unexpected file format: \($0)")
			}
		}
	}

	private static func handleZipEmbeddedInfoItem(
		zipFile: URL,
		downloadsLink: URL,
		downloadURLPrefix: URL,
		signatureGenerator: (URL) throws -> String?
	) throws -> AppcastItem {
		let zipArchive = try Archive(url: zipFile, accessMode: .read)

		let zipResources = try zipFile.resourceValues(forKeys: [.fileSizeKey])
		let zipSize = try zipResources.fileSize.unwrap()

		let (directories, files) = try zipArchive.reduce(into: ([Entry](), [Entry]())) {
			switch $1.type {
			case .directory:
				$0.0.append($1)
			case .file:
				$0.1.append($1)
			case .symlink:
				try print("symlink: \($1.pathURL.unwrap())")
				break
			}
		}

		let sortedDirectories = directories.sorted(by: {
			$0.componentCount < $1.componentCount
		})

		var appEntry: Entry?
		var level = 0
		for directory in sortedDirectories {
			let newLevel = max(level, directory.componentCount)
			defer { level = newLevel }
			if newLevel > level, appEntry != nil {
				break
			}
			
			guard
				directory.pathURL?.pathExtension.lowercased() == "app"
			else { continue }
			guard
				appEntry == nil
			else {
				throw CustomError(
					message: "Too many app bundles in this package. You only have one app per archive (not including embedded helper apps)")
			}

			appEntry = directory
		}

		guard let appEntry else { throw CustomError(message: "No app bundle found in this package!") }
		let infoPath = try appEntry.pathURL.unwrap().appending(components: "Contents", "Info.plist")
		guard
			let infoEntry = files.first(where: { $0.pathURL == infoPath })
		else { throw CustomError(message: "App bundle doesn't have an Info.plist. Something is corrupt!") }

		var accumulator = Data()
		_ = try zipArchive.extract(infoEntry, skipCRC32: true) { newData in
			accumulator.append(newData)
		}

		let infoPlist = try (PropertyListSerialization.propertyList(from: accumulator, format: nil) as? [String: Any]).unwrap()

		let buildNumber = try (infoPlist["CFBundleVersion"] as? String).unwrap()
		let versionNumber = try (infoPlist["CFBundleShortVersionString"] as? String).unwrap()
		let systemRequirement = infoPlist["LSMinimumSystemVersion"] as? String

		let enclosure = try AppcastItem.Enclosure(
			url: downloadURLPrefix.appending(component: zipFile.lastPathComponent),
			length: zipSize,
			mimeType: "application/zip",
			edSignature: signatureGenerator(zipFile),
			installationType: nil)

		return .init(
			title: versionNumber,
			link: downloadsLink,
			releaseNotesLink: nil,
			fullReleaseNotesLink: nil,
			version: buildNumber,
			shortVersionString: versionNumber,
			description: nil,
			publishedDate: .now,
			enclosure: enclosure,
			minimumSystemVersion: systemRequirement,
			maximumSystemVersion: nil,
			minimumAutoUpdateVersion: nil,
			ignoreSkippedUpgradesBelowVersion: nil,
			criticalUpdate: nil,
			phasedRolloutInterval: nil)
	}
}
