import Foundation

public struct CustomError: Error {
	public let message: String

	public init(message: String) {
		self.message = message
	}
}
