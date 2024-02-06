import Foundation
import XMLCoder

public struct AppcastItem: Codable, Hashable {
	public var title: String
	public var link: URL
	public var releaseNotesLink: URL?
	public var fullReleaseNotesLink: URL?
	public var version: String
	public var shortVersionString: String?
	public var description: String?
	public var publishedDate: Date
	public var enclosure: Enclosure
	public var minimumSystemVersion: String?
	public var maximumSystemVersion: String?
	public var minimumAutoUpdateVersion: String?
	public var ignoreSkippedUpgradesBelowVersion: String?

	/// This value would be `1.2.4` in `<sparkle:criticalUpdate sparkle:version="1.2.4"></sparkle:criticalUpdate>`
	public var criticalUpdateVersion: String? {
		get { criticalUpdate?.version }
		set { criticalUpdate?.version = newValue }
	}
	public var criticalUpdate: CriticalUpdate?
	public var phasedRolloutInterval: Int?

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
		criticalUpdateVersion: String? = nil,
		criticalUpdate: Bool = false,
		phasedRolloutInterval: Int? = nil
	) {
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
		self.criticalUpdate = criticalUpdate ? CriticalUpdate(version: criticalUpdateVersion) : nil
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

	public struct Enclosure: Codable, DynamicNodeDecoding, DynamicNodeEncoding, Hashable {
		public var url: URL
		public var length: Int
		public var mimeType: String
		public var edSignature: String?
		public var installationType: String?

		static public func nodeDecoding(for key: CodingKey) -> XMLDecoder.NodeDecoding { .attribute }
		static public func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding { .attribute }

		public init(
			url: URL,
			length: Int,
			mimeType: String,
			edSignature: String? = nil,
			installationType: String? = nil
		) {
			self.url = url
			self.length = length
			self.mimeType = mimeType
			self.edSignature = edSignature
			self.installationType = installationType
		}
		
		enum CodingKeys: String, CodingKey {
			case url
			case length
			case mimeType = "type"
			case edSignature = "sparkle:edSignature"
			case installationType = "sparkle:installationType"
		}
	}

	public struct CriticalUpdate: Codable, DynamicNodeDecoding, DynamicNodeEncoding, Hashable {
		var version: String?

		enum CodingKeys: String, CodingKey {
			case version = "sparkle:version"
		}

		static public func nodeDecoding(for key: CodingKey) -> XMLDecoder.NodeDecoding { .attribute }
		static public func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding { .attribute }
	}
}

public extension AppcastItem {
	init(from appCast: JSONAppcastItem, enclosure: Enclosure, isPackage: Bool? = nil) throws {
		var enclosure = enclosure
		if appCast.isPackage == true || isPackage == true {
			enclosure.installationType = "package"
			try appCast.validateForPKG()
		}
		try self.init(
			title: appCast.title.unwrap(),
			link: appCast.link.unwrap(),
			releaseNotesLink: appCast.releaseNotesLink,
			fullReleaseNotesLink: appCast.fullReleaseNotesLink,
			version: appCast.version.unwrap(),
			shortVersionString: appCast.shortVersionString,
			description: appCast.description,
			publishedDate: Date(),
			enclosure: enclosure,
			minimumSystemVersion: appCast.minimumSystemVersion,
			maximumSystemVersion: appCast.maximumSystemVersion,
			minimumAutoUpdateVersion: appCast.minimumAutoUpdateVersion,
			ignoreSkippedUpgradesBelowVersion: appCast.ignoreSkippedUpgradesBelowVersion,
			criticalUpdateVersion: appCast.criticalUpdateVersion,
			criticalUpdate: appCast.criticalUpdate ?? false,
			phasedRolloutInterval: appCast.phasedRolloutInterval)
	}

	mutating func update(from jsonItem: JSONAppcastItem) {
		self.title = jsonItem.title ?? title
		self.link = jsonItem.link ?? link
		self.releaseNotesLink = jsonItem.releaseNotesLink ?? releaseNotesLink
		self.fullReleaseNotesLink = jsonItem.fullReleaseNotesLink ?? fullReleaseNotesLink
		self.version = jsonItem.version ?? version
		self.shortVersionString = jsonItem.shortVersionString ?? shortVersionString
		self.description = jsonItem.description ?? description
		self.minimumSystemVersion = jsonItem.minimumSystemVersion ?? minimumSystemVersion
		self.maximumSystemVersion = jsonItem.maximumSystemVersion ?? maximumSystemVersion
		self.minimumAutoUpdateVersion = jsonItem.minimumAutoUpdateVersion ?? minimumAutoUpdateVersion
		self.ignoreSkippedUpgradesBelowVersion = jsonItem.ignoreSkippedUpgradesBelowVersion ?? ignoreSkippedUpgradesBelowVersion
		if let criticalUpdate = jsonItem.criticalUpdate {
			if criticalUpdate {
				self.criticalUpdate = CriticalUpdate(version: jsonItem.criticalUpdateVersion)
			} else if let criticalUpdateVersion = jsonItem.criticalUpdateVersion {
				self.criticalUpdate = nil
			}
		}
		self.phasedRolloutInterval = jsonItem.phasedRolloutInterval ?? phasedRolloutInterval
	}
}
