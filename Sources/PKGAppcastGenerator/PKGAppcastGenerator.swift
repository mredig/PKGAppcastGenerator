import Foundation
import ArgumentParser
import PKGAppcastGeneratorCore
import AppKit

@main
struct PKGAppcastGenerator: AsyncParsableCommand {

	@Argument(
		help: "The directory with the latest update and information.",
		completion: .directory,
		transform: {
			URL(filePath: $0, relativeTo: .currentDirectory())
		})
	var directory: URL

	@Option(
		name: .shortAndLong,
		help: "Download and append to this online app cast. Optional.",
		transform: {
			URL(string: $0)
		})
	var existingAppcastURL: URL?

	@Option(
		name: .long,
		help: "Download and append to this offline app cast. Optional.",
		transform: {
			URL(filePath: $0, relativeTo: .currentDirectory())
		})
	var existingAppcastFile: URL?

	@Option(
		name: .shortAndLong,
		help: """
			The root url download prefix of the file(s). If a given update will be available at \
			`https://foo.com/path/to/bar.zip`, this value would need to be `https://foo.com/path/to/`
			""",
		transform: {
			guard let url = URL(string: $0) else {
				throw CustomError(message: "The provided download URL Prefix is not a valid url")
			}
			return url
		})
	var downloadURLPrefix: URL

	@Option(
		name: .shortAndLong,
		help: """
			The title for the channel. Defaults to "App Changelog"
			""")
	var channelTitle: String?

	@Option(
		name: .shortAndLong,
		help: "Where to save the output file. Defaults to `./appcast.xml`.",
		transform: {
			URL(filePath: $0, relativeTo: .currentDirectory())
		})
	var outputPath: URL?

	mutating func run() async throws {
		var outputPath = self.outputPath ?? .currentDirectory()
		if outputPath.hasDirectoryPath {
			outputPath.appendPathComponent("appcast", conformingTo: .xml)
		}

		var previousData: Data?
		if let existingAppcastFile {
			guard existingAppcastURL == nil else {
				throw CustomError(message: "Cannot have both --existingAppcastFile and --existingAppcastURL")
			}
			previousData = try Data(contentsOf: existingAppcastFile)
		}
		if let existingAppcastURL {
			guard existingAppcastFile == nil else {
				throw CustomError(message: "Cannot have both --existingAppcastFile and --existingAppcastURL")
			}
			previousData = try await URLSession.shared.data(from: existingAppcastURL).0
		}

		let appcastData = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: directory,
			previousAppcastData: previousData,
			channelTitle: channelTitle ?? "App Changelog",
			downloadURLPrefix: downloadURLPrefix)

//		try appcastData.write(to: outputPath)
		print(String(data: appcastData, encoding: .utf8)!)
	}
}

