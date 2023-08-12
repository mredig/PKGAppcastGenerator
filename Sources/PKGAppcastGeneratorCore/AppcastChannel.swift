import Foundation

public struct AppcastChannel: Codable {
	public let title: String
	public let link: URL?
	public let description: String?
	public let language: String?
	public let items: [AppcastItem]

	public init(
		title: String,
		link: URL? = nil,
		description: String? = nil,
		language: String? = nil,
		items: [AppcastItem]) {
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
}
