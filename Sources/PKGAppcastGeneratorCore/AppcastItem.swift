import Foundation
import XMLCoder

public struct AppcastItem: Codable {
	public let title: String
	public let link: URL
	public let releaseNotesLink: URL?
	public let fullReleaseNotesLink: URL?
	public let version: String
	public let shortVersionString: String?
	public let description: String?
	public let publishedDate: Date
	public let enclosure: Enclosure
	public let minimumSystemVersion: String?
	public let maximumSystemVersion: String?
	public let minimumAutoUpdateVersion: String?
	public let ignoreSkippedUpgradesBelowVersion: String?

	/// This value would be `1.2.4` in `<sparkle:criticalUpdate sparkle:version="1.2.4"></sparkle:criticalUpdate>`
	public let criticalUpdate: String?
	public let phasedRolloutInterval: Int?

	public init(
		title: String,
		link: URL,
		releaseNotesLink: URL? = nil,
		fullReleaseNotesLink: URL? = nil,
		version: String,
		shortVersionString: String? = nil,
		description: String?,
		publishedDate: Date,
		enclosure: AppcastItem.Enclosure,
		minimumSystemVersion: String? = nil,
		maximumSystemVersion: String? = nil,
		minimumAutoUpdateVersion: String? = nil,
		ignoreSkippedUpgradesBelowVersion: String? = nil,
		criticalUpdate: String? = nil,
		phasedRolloutInterval: Int? = nil) {
			self.title = title
			self.link = link
			self.releaseNotesLink = releaseNotesLink
			self.fullReleaseNotesLink = fullReleaseNotesLink
			self.version = version
			self.shortVersionString = shortVersionString
			self.description = description
			self.publishedDate = publishedDate
			self.enclosure = enclosure
			self.minimumSystemVersion = minimumSystemVersion
			self.maximumSystemVersion = maximumSystemVersion
			self.minimumAutoUpdateVersion = minimumAutoUpdateVersion
			self.ignoreSkippedUpgradesBelowVersion = ignoreSkippedUpgradesBelowVersion
			self.criticalUpdate = criticalUpdate
			self.phasedRolloutInterval = phasedRolloutInterval
		}

	enum CodingKeys: String, CodingKey {
		case title
		case link
		case releaseNotesLink = "sparkle:releaseNotesLink"
		case fullReleaseNotesLink = "sparkle:fullReleaseNotesLink"
		case version = "sparkle:version"
		case shortVersionString = "sparkle:shortVersionString"
		case description
		case publishedDate = "pubDate"
		case enclosure
		case minimumSystemVersion = "sparkle:minimumSystemVersion"
		case maximumSystemVersion = "sparkle:maximumSystemVersion"
		case minimumAutoUpdateVersion = "sparkle:minimumAutoUpdateVersion"
		case ignoreSkippedUpgradesBelowVersion = "sparkle:ignoreSkippedUpgradesBelowVersion"
		case criticalUpdate = "sparkle:criticalUpdate"
		case phasedRolloutInterval = "sparkle:phasedRolloutInterval"
	}

	public struct Enclosure: Codable, DynamicNodeDecoding, DynamicNodeEncoding {
		public let url: URL
		public let length: Int
		public let type: String
		public let edSignature: String
		public let installationType: String?

		static public func nodeDecoding(for key: CodingKey) -> XMLDecoder.NodeDecoding { .attribute }

		static public func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding { .attribute }
		
		enum CodingKeys: String, CodingKey {
			case url
			case length
			case type
			case edSignature = "sparkle:edSignature"
			case installationType = "sparkle:installationType"
		}
	}
}

public extension AppcastItem {
	init(from appCast: JSONAppcastItem, enclosure: Enclosure) {
		self.init(
			title: appCast.title,
			link: appCast.link,
			releaseNotesLink: appCast.releaseNotesLink,
			fullReleaseNotesLink: appCast.fullReleaseNotesLink,
			version: appCast.version,
			shortVersionString: appCast.shortVersionString,
			description: appCast.description,
			publishedDate: Date(),
			enclosure: enclosure,
			minimumSystemVersion: appCast.minimumSystemVersion,
			maximumSystemVersion: appCast.maximumSystemVersion,
			minimumAutoUpdateVersion: appCast.minimumAutoUpdateVersion,
			ignoreSkippedUpgradesBelowVersion: appCast.ignoreSkippedUpgradesBelowVersion,
			criticalUpdate: appCast.criticalUpdate,
			phasedRolloutInterval: appCast.phasedRolloutInterval)
	}
}
