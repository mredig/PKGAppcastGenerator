import Foundation

public struct AppcastChannel: Codable {
	public var title: String
	public var link: URL?
	public var description: String?
	public var language: String?
	public var items: [AppcastItem]

	public init(
		title: String,
		link: URL? = nil,
		description: String? = nil,
		language: String? = nil,
		items: [AppcastItem]
	) {
		self.title = title
		self.link = link
		self.description = description
		self.language = language
		self.items = items
	}

	enum CodingKeys: String, CodingKey {
		case title
		case link
		case description
		case language
		case items = "item"
	}

	public mutating func sortItems(
		by comparison: (AppcastItem, AppcastItem) throws -> Bool = Self.defaultSortItems
	) rethrows {
		try items.sort(by: comparison)
	}

	public static func defaultSortItems(_ first: AppcastItem, _ second: AppcastItem) -> Bool {
		if let a = Int(first.version), let b = Int(second.version) {
			return a > b
		} else if let a = first.shortVersionString, let b = second.shortVersionString {
			let aParts = a.split(separator: ".").compactMap { Int($0) }
			let bParts = b.split(separator: ".").compactMap { Int($0) }

			let zipped = zip(aParts, bParts)
			for pair in zipped {
				guard pair.0 > pair.1 else { continue }
				return true
			}

			if a.count > b.count {
				return true
			} else if b.count > a.count {
				return true
			} else {
				return false
			}
		} else {
			return true
		}
	}
}
