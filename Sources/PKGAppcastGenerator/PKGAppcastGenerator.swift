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
		name: .long,
		help: """
			Backup URL that a user can go manually download the updates. The json files include this already, but if you have \
			any non json archives as updates, this is a required value.
			""",
		transform: { URL(string: $0) })
	var downloadsLink: URL?

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

	@Option(
		name: .long,
		help: "Path to Sparkle's `sign_update` executable",
		transform: {
			URL(filePath: $0, relativeTo: .currentDirectory())
		})
	var signUpdatePath: URL?

	@Option(
		name: .long,
		help: "Account value for Sparkle's `sign_update` executable")
	var signUpdateAccount: String?

	@Option(
		name: .long,
		help: "Path to EdDSA file for `sign_update` executable",
		transform: {
			URL(filePath: $0, relativeTo: .currentDirectory())
		})
	var signUpdateKeyFile: URL?

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
			downloadsLink: downloadsLink,
			signatureGenerator: signaureGenerator,
			downloadURLPrefix: downloadURLPrefix)

		try appcastData.write(to: outputPath)
	}

	private func signaureGenerator(fileToSign: URL) throws -> String? {
		guard let signUpdatePath else { return nil }

		var args: [String] = ["-p"]
		if let signUpdateAccount {
			args.append("--account")
			args.append(signUpdateAccount)
		}

		if let signUpdateKeyFile {
			args.append("--ed-key-file")
			args.append(signUpdateKeyFile.path(percentEncoded: false))
		}

		return try Self
			.runSignatureGenerator(pathToExe: signUpdatePath, arguments: args, fileToSign: fileToSign)
			.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private static func runSignatureGenerator(pathToExe: URL, arguments: [String], fileToSign: URL) throws -> String {
		let stdOut = Pipe()

		let process = Process()
		process.standardOutput = stdOut
		process.standardError = stdOut
		process.arguments = arguments + [fileToSign.absoluteURL.path(percentEncoded: false)]
		process.executableURL = pathToExe.absoluteURL
		process.currentDirectoryURL = .currentDirectory()

		do {
			try process.run()
		} catch let error as CocoaError {
			let code = error.code
			switch code {
			case .fileReadNoSuchFile:
				print("file read none: \(error)")
			case .fileNoSuchFile:
				print("no such file: \(error)")
			default: print("other: \(code)")
			}
			throw CocoaError(code)
		} catch {
			print("caught the error: \(error)")
			throw error
		}
		process.waitUntilExit()

		guard
			let out = try stdOut.fileHandleForReading.readToEnd()
		else { return "" }

		return String(data: out, encoding: .utf8) ?? ""
	}
}

