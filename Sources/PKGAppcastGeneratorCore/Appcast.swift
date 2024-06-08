import Foundation

public struct Appcast: Codable {
	public var channel: RSSAppcastChannel

	enum CodingKeys: String, CodingKey {
		case channel = "channel"
	}
}
