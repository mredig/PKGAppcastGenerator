import Foundation

public struct JSONAppcastItem: Codable {
	public let title: String?
	public let link: URL?
	public let channel: String?
	public let releaseNotesLink: URL?
	public let fullReleaseNotesLink: URL?
	public let version: String?
	public let shortVersionString: String?
	public let description: String?
	public let minimumSystemVersion: String?
	public let maximumSystemVersion: String?
	public let minimumAutoUpdateVersion: String?
	public let ignoreSkippedUpgradesBelowVersion: String?
	
	/// Simply indicates if an update is critical or not.
	public let criticalUpdate: Bool?
	/// This value would be `1.2.4` in `<sparkle:criticalUpdate sparkle:version="1.2.4"></sparkle:criticalUpdate>`
	public let criticalUpdateVersion: String?
	public let phasedRolloutInterval: Int?

	public var isPackage: Bool?

	public func validateForPKG() throws {
		guard title != nil else { throw JSONAppcastError.missingPKGTitle }
		guard link != nil else { throw JSONAppcastError.missingPKGLink }
		guard version != nil else { throw JSONAppcastError.missingPKGVersion }
	}

	public enum JSONAppcastError: Error {
		case missingPKGTitle
		case missingPKGLink
		case missingPKGVersion
	}
}
