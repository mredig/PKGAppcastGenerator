import Foundation

/// Not to be confused with `AppcastItem` channels. This one is something built into the rss spec, while
/// `AppcastItem.channel` is the channel categorization tool from Sparkle.
public struct RSSAppcastChannel: Codable {
	public static let defaultChannel = "default"

	public var title: String
	public var link: URL?
	public var description: String?
	public var language: String?
	public var itemChannels: [String: [AppcastItem]]
	public var items: [AppcastItem] {
		let defaultChannel = itemChannels[Self.defaultChannel] ?? []
		let remainingKeys = itemChannels.keys.filter { $0 != Self.defaultChannel }.sorted()
		let remainingChannels = remainingKeys.reduce(into: [AppcastItem]()) {
			guard let items = itemChannels[$1] else { return }
			$0.append(contentsOf: items)
		}
		return defaultChannel + remainingChannels
	}

	public init(
		title: String? = nil,
		link: URL? = nil,
		description: String? = nil,
		language: String? = nil,
		items: [AppcastItem]
	) {
		self.init(
			title: title,
			link: link,
			description: description,
			language: language,
			itemChannels: [Self.defaultChannel: items])
	}

	public init(
		title: String? = nil,
		link: URL? = nil,
		description: String? = nil,
		language: String? = nil,
		itemChannels: [String: [AppcastItem]]
	) {
		self.title = title ?? "App Changelog"
		self.link = link
		self.description = description
		self.language = language
		self.itemChannels = itemChannels
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let title = try container.decodeIfPresent(String.self, forKey: .title)
		let link = try container.decodeIfPresent(URL.self, forKey: .link)
		let description = try container.decodeIfPresent(String.self, forKey: .description)
		let language = try container.decodeIfPresent(String.self, forKey: .language)
		let items = try container.decode([AppcastItem].self, forKey: .items)

		let itemChannels = items.reduce(into: [String: [AppcastItem]]()) {
			$0[$1.channel ?? Self.defaultChannel, default: []].append($1)
		}

		self.init(
			title: title,
			link: link,
			description: description,
			language: language,
			itemChannels: itemChannels)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(title, forKey: .title)
		try container.encodeIfPresent(link, forKey: .link)
		try container.encodeIfPresent(description, forKey: .description)
		try container.encodeIfPresent(language, forKey: .language)
		
		let flattenedItems = itemChannels.flatMap { $0.value }

		try container.encode(flattenedItems, forKey: .items)
	}

	enum CodingKeys: String, CodingKey {
		case title
		case link
		case description
		case language
		case items = "item"
	}

	public mutating func appendItems(_ items: [AppcastItem], to channel: String?, fixIncorrectChannels: Bool = false) {
		let internalChannel = channel ?? Self.defaultChannel
		var currentItems = self.itemChannels[internalChannel] ?? []

		let existingURLs = Set(itemChannels.flatMap(\.value).map(\.enclosure.url))

		for var item in items {
			guard
				existingURLs.contains(item.enclosure.url) == false
			else {
				print("Not appending \(item) as it's already included")
				continue
			}

			if item.channel != channel {
				if fixIncorrectChannels {
					item.channel = internalChannel
				} else {
					print("Skipping \(item) because it's not in \(internalChannel) channel")
					continue
				}
			}

			currentItems.append(item)
		}
		self.itemChannels[internalChannel] = currentItems
	}

	public mutating func sortItems(
		by comparison: (AppcastItem, AppcastItem) throws -> Bool = Self.defaultSortItems,
		in channel: String? = nil
	) rethrows {
		let channel = channel ?? Self.defaultChannel
		var items = itemChannels[channel] ?? []
		try items.sort(by: comparison)
		itemChannels[channel] = items
	}

	public static func defaultSortItems(_ first: AppcastItem, _ second: AppcastItem) -> Bool {
		if let a = first.shortVersionString, let b = second.shortVersionString {
			let aParts = a.split(separator: ".").compactMap { Int($0) }
			let bParts = b.split(separator: ".").compactMap { Int($0) }

			let zipped = zip(aParts, bParts)
			for pair in zipped {
				guard pair.0 != pair.1 else { continue }
				return pair.0 > pair.1
			}

			if a.count != b.count {
				return a.count > b.count
			}
		} 

		if let a = Int(first.version), let b = Int(second.version), a != b {
			return a > b
		} else {
			return first.publishedDate > second.publishedDate
		}
	}

	public mutating func cullItems(afterFirst count: Int, in channel: String? = nil) {
		let channel = channel ?? Self.defaultChannel
		var items = itemChannels[channel] ?? []
		guard items.count > count else { return }
		let range = items.startIndex..<items.index(items.startIndex, offsetBy: count)
		items = Array(items[range])
		itemChannels[channel] = items
	}
}
