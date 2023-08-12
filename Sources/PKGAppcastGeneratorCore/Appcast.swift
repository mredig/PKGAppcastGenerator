import Foundation

public struct Appcast: Codable {
	public var channel: AppcastChannel

	enum CodingKeys: String, CodingKey {
		case channel = "channel"
	}
}
