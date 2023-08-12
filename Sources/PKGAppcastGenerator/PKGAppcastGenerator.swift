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
			The url the appcast will be hosted at.
			""",
		transform: {
			guard let url = URL(string: $0) else {
				throw CustomError(message: "The provided appcast url is not a valid url")
			}
			return url
		})
	var appcastURL: URL

	@Option(
		name: .shortAndLong,
		help: """
			The title for the channel. Defaults to "App Changelog"
			""")
	var channelTitle: String?

	mutating func run() async throws {
		try PKGAppcastGeneratorCore.asdf()
	}
}


struct CustomError: Error {
	let message: String
}
