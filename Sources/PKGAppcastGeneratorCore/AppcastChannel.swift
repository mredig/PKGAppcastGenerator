import Foundation

public struct AppcastChannel: Codable {
	public let title: String
	public let link: URL
	public let description: String
	public let language: String
	public let items: [AppcastItem]

	enum CodingKeys: String, CodingKey {
		case title
		case link
		case description
		case language
		case items = "item"
	}
}
