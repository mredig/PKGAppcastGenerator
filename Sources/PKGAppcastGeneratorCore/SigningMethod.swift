import Foundation
import EdDSA_Signing
import Security
import SwiftPizzaSnips

public struct SigningMethod {
	public let signatureGenerator: (URL) throws -> String?

	init(signatureGenerator: @escaping (URL) throws -> String?) {
		self.signatureGenerator = signatureGenerator
	}

	public static func custom(_ block: @escaping (URL) throws -> String?) -> SigningMethod {
		SigningMethod(signatureGenerator: block)
	}

	public static func retrieveFromKeychain(account: String) -> SigningMethod {
		SigningMethod { fileToSign in
			let keychainSearchAttributes = [
				kSecClass as String: kSecClassGenericPassword as String,
				kSecAttrService as String: "https://sparkle-project.org",
				kSecAttrAccount as String: account,
				kSecAttrProtocol as String: kSecAttrProtocolSSH as String,
				kSecReturnData as String: true as CFBoolean,
			]
			var keychainItem: CFTypeRef?
			let successIndicator = SecItemCopyMatching(keychainSearchAttributes as CFDictionary, &keychainItem)

			guard successIndicator == errSecSuccess else { throw SimpleError(message: "Error: \(successIndicator)") }
			guard
				let secretB64Data = (keychainItem as? Data),
				let privateKey = Data(base64Encoded: secretB64Data)
			else { throw SimpleError(message: "Invalid data") }

			let fileData = try Data(contentsOf: fileToSign)

			let signatureData = try Signing.sign(data: fileData, withKey: privateKey)

			guard
				try Signing.verify(data: fileData, withSignature: signatureData, forPrivateKey: privateKey)
			else {
				print("Failed to verify signing key worked for \(fileToSign.lastPathComponent)")
				return nil
			}

			return signatureData.base64EncodedString()
		}
	}

	public static func privateKeyfile(_ keyfileURL: URL) -> SigningMethod {
		SigningMethod { fileToSign in
			let fileData = try Data(contentsOf: fileToSign)
			let privateKey = try {
				let base64 = try Data(contentsOf: keyfileURL)
				return try Data(base64Encoded: base64, options: .ignoreUnknownCharacters).unwrap("invalid base64 data")
			}()

			let signatureData = try Signing.sign(data: fileData, withKey: privateKey)

			guard
				try Signing.verify(data: fileData, withSignature: signatureData, forPrivateKey: privateKey)
			else {
				print("Failed to verify signing key worked for \(fileToSign.lastPathComponent)")
				return nil
			}

			return signatureData.base64EncodedString()
		}
	}
}
