import Foundation
import SwiftPizzaSnips
import EdDSA_Signing

@available(macOS 14.0, *)
@Observable
@MainActor
class SignatureCheckerViewModel {
	var selectedFile: URL? {
		didSet {
			validationStatus = .unknown
		}
	}
	var selectedFilename: String? { selectedFile?.lastPathComponent }
	var base64Signature: String = "" {
		didSet {
			validationStatus = .unknown
		}
	}
	var base64PublicKey: String = "" {
		didSet {
			validationStatus = .unknown
		}
	}

	enum ValidationStatus: String {
		case unknown
		case invalid
		case valid
	}
	private(set) var validationStatus: ValidationStatus = .unknown

	private(set) var isProcessing = false

	func verifySigatureIsValid() async throws {
		var finishStatus: ValidationStatus = .unknown
		defer {
			self.validationStatus = finishStatus
		}
		guard
			isProcessing == false,
			let selectedFile,
			let base64Signature = base64Signature.emptyIsNil,
			let base64PublicKey = base64PublicKey.emptyIsNil,
			let signatureData = Data(base64Encoded: base64Signature),
			let publicKeyData = Data(base64Encoded: base64PublicKey)
		else { throw SimpleError(message: "Incomplete or invalid data") }
		isProcessing = true
		defer { isProcessing = false }

		finishStatus = try await verifySignature(selectedFile, signatureData: signatureData, publicKeyData: publicKeyData)
	}

	private func verifySignature(_ fileURL: URL, signatureData: Data, publicKeyData: Data) async throws -> ValidationStatus {
		let fileData = try Data(contentsOf: fileURL)

		let result = try Signing.verify(data: fileData, withSignature: signatureData, forPublicKey: publicKeyData)
		if result {
			return .valid
		} else {
			return .invalid
		}
	}
}
