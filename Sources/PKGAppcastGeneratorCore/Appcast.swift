import Foundation

public struct Appcast: Codable {
	public let channels: [AppcastChannel]

	enum CodingKeys: String, CodingKey {
		case channels = "channel"
	}
}
