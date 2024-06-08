import Foundation
import XMLCoder
import SwiftPizzaSnips
import ZIPFoundation

public enum PKGAppcastGeneratorCore {
	static let jsonDecoder = JSONDecoder()

	private static let allowedUpdaterExtensions = Set(
		[
			"pkg",
			"mpkg",
			"zip",
			"dmg"
		])
	private static let requirePairedJSONExtensions = allowedUpdaterExtensions.with {
		$0.remove("zip")
	}

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
			channel: nil,
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


		let channel = RSSAppcastChannel(
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
		maximumVersionsToRetain: Int?,
		rssChannelTitle: String?,
		appcastChannelName: String?,
		downloadsLink: URL?,
		signatureGenerator: (URL) throws -> String?,
		downloadURLPrefix: URL
	) throws -> Data {

		let directoryContents = try FileManager.default.contentsOfDirectory(at: contentsOfDirectory, includingPropertiesForKeys: nil)
		let jsonFiles = directoryContents.filter { $0.pathExtension.lowercased() == "json" }

		let updaterFiles = directoryContents.filter { url in
			allowedUpdaterExtensions.contains(url.pathExtension.lowercased())
		}

		let jsonDict = jsonFiles.reduce(into: [String: URL]()) { jsonMap, jsonFile in
			jsonMap[jsonFile.deletingPathExtension().lastPathComponent] = jsonFile
		}
		let fileGroups = try updaterFiles.reduce(into: FileGroups()) {
			let basename = $1.deletingPathExtension().lastPathComponent
			if let jsonFile = jsonDict[basename] {
				$0.pairedItems.append(.init(json: jsonFile, updateFile: $1))
				if requirePairedJSONExtensions.contains($1.pathExtension.lowercased()) == false {
					$0.embeddedDataUpdateFiles.append($1)
				}
			} else {
				guard
					requirePairedJSONExtensions.contains($1.pathExtension.lowercased()) == false
				else { throw CustomError(message: "pkg, mpkg, and dmg files all require json companion files.") }
				$0.embeddedDataUpdateFiles.append($1)
			}
		}

		guard
			jsonDict.count == fileGroups.pairedItems.count
		else { throw CustomError(message: "There are json files unpaired with an update file.") }

		let decodedJSONObjects = try fileGroups.pairedItems.reduce(into: [URL: JSONAppcastItem]()) { verifiedAppcastItems, pairedUpdateFile in
			let data = try Data(contentsOf: pairedUpdateFile.json)
			let jsonAppcast = try Self.jsonDecoder.decode(JSONAppcastItem.self, from: data)
			if requirePairedJSONExtensions.contains(pairedUpdateFile.updateFile.pathExtension.lowercased()) {
				try jsonAppcast.validateForPKG()
			}
			verifiedAppcastItems[pairedUpdateFile.updateFile] = jsonAppcast
		}

		let appcastsFromJSON = try getAppcastFromJSONOnlyPairs(
			jsonDict: decodedJSONObjects,
			downloadURLPrefix: downloadURLPrefix,
			appcastChannelFallback: appcastChannelName,
			signatureGenerator: signatureGenerator)

		let embeddedInfoItems = try handleEmbeddedInfoItems(
			embeddedUpdaterFiles: fileGroups.embeddedDataUpdateFiles,
			decodedJSONObjects: decodedJSONObjects,
			downloadsLink: downloadsLink,
			downloadURLPrefix: downloadURLPrefix, 
			appcastChannel: appcastChannelName,
			signatureGenerator: signatureGenerator)

		var appCast: Appcast
		if let previousAppcastData {
			let decoder = XMLDecoder()
			decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)

			appCast = try decoder.decode(Appcast.self, from: previousAppcastData)
		} else {
			appCast = Appcast(channel: RSSAppcastChannel(title: rssChannelTitle, items: []))
		}

		if let rssChannelTitle {
			appCast.channel.title = rssChannelTitle
		}
		appCast.channel.appendItems(appcastsFromJSON)
		appCast.channel.appendItems(embeddedInfoItems)
		appCast.channel.sortItems(by: RSSAppcastChannel.defaultSortItems)
		if let maximumVersionsToRetain {
			appCast.channel.cullItems(afterFirst: maximumVersionsToRetain)
		}

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

	private static func getAppcastFromJSONOnlyPairs(
		jsonDict: [URL: JSONAppcastItem],
		downloadURLPrefix: URL,
		appcastChannelFallback: String?,
		signatureGenerator: (URL) throws -> String?
	) throws -> [AppcastItem] {
		try jsonDict.compactMap { (updateFile, jsonAppcast) in
			guard
				requirePairedJSONExtensions.contains(updateFile.pathExtension.lowercased())
			else { return nil }
			guard
				let fileSize = try updateFile.resourceValues(forKeys: [.fileSizeKey]).fileSize
			else { throw CustomError(message: "Cannot retrieve file size for \(updateFile.lastPathComponent).") }

			let isPackage = updateFile.pathExtension.contains("pkg")
			let enclosure = AppcastItem.Enclosure(
				url: downloadURLPrefix.appending(component: updateFile.lastPathComponent),
				length: fileSize,
				mimeType: "application/octet-stream",
				edSignature: try signatureGenerator(updateFile),
				installationType: isPackage ? "package" : nil)
			return try AppcastItem(from: jsonAppcast, appcastChannelFallback: appcastChannelFallback, enclosure: enclosure)
		}
	}

	private static func handleJSONFilePairs(
		jsonFiles: [URL],
		jsonPKGFiles: [URL],
		downloadURLPrefix: URL,
		appcastChannelFallback: String?,
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

			let isPackage = pkgFile.pathExtension.contains("pkg")
			let enclosure = AppcastItem.Enclosure(
				url: downloadURLPrefix.appending(component: pkgFile.lastPathComponent),
				length: fileSize,
				mimeType: "application/octet-stream",
				edSignature: try signatureGenerator(pkgFile),
				installationType: isPackage ? "package" : nil)
			return try AppcastItem(from: jsonItem, appcastChannelFallback: appcastChannelFallback, enclosure: enclosure, isPackage: isPackage)
		}
		return items
	}

	private static func handleEmbeddedInfoItems(
		embeddedUpdaterFiles: [URL],
		decodedJSONObjects: [URL: JSONAppcastItem],
		downloadsLink: URL?,
		downloadURLPrefix: URL,
		appcastChannel: String?,
		signatureGenerator: (URL) throws -> String?
	) throws -> [AppcastItem] {
		guard embeddedUpdaterFiles.isOccupied else { return [] }
		guard let downloadsLink else {
			throw CustomError(message: "With embedded files, you need to provide a downloads link! See help.")
		}

		return try embeddedUpdaterFiles.map {
			switch $0.pathExtension.lowercased() {
			case "zip":
				var appcastItem = try handleZipEmbeddedInfoItem(
					zipFile: $0,
					downloadsLink: downloadsLink,
					downloadURLPrefix: downloadURLPrefix, 
					appcastChannel: appcastChannel,
					signatureGenerator: signatureGenerator)
				if let jsonAppcastItem = decodedJSONObjects[$0] {
					appcastItem.update(from: jsonAppcastItem)
				}

				return appcastItem
			default:
				throw CustomError(message: "Unexpected file format: \($0)")
			}
		}
	}

	private static func handleZipEmbeddedInfoItem(
		zipFile: URL,
		downloadsLink: URL,
		downloadURLPrefix: URL,
		appcastChannel: String?,
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
			channel: appcastChannel,
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
			criticalUpdateVersion: nil,
			criticalUpdate: false,
			phasedRolloutInterval: nil)
	}

	struct FileGroups {
		   var pairedItems: [PairedItem] = []
		   var embeddedDataUpdateFiles: [URL] = []

		   struct PairedItem {
			   let json: URL
			   let updateFile: URL
		   }
	   }
}
