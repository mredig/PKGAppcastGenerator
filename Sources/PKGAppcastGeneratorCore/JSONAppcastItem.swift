import Foundation

public struct JSONAppcastItem: Codable {
	public let title: String
	public let link: URL
	public let releaseNotesLink: URL?
	public let fullReleaseNotesLink: URL?
	public let version: String
	public let shortVersionString: String?
	public let description: String?
	public let minimumSystemVersion: String?
	public let maximumSystemVersion: String?
	public let minimumAutoUpdateVersion: String?
	public let ignoreSkippedUpgradesBelowVersion: String?
	
	/// This value would be `1.2.4` in `<sparkle:criticalUpdate sparkle:version="1.2.4"></sparkle:criticalUpdate>`
	public let criticalUpdate: String?
	public let phasedRolloutInterval: Int?

	public let isPackage: Bool?
}
