import Foundation
import CryptoKit

public enum Signing {
	public static func sign(data: Data, withKey privateKeyData: Data) throws -> Data {
		let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)

		return try privateKey.signature(for: data)
	}


	public static func verify(data: Data, withSignature signature: Data, forPrivateKey privateKeyData: Data) throws -> Bool {
		let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)

		let publicKey = privateKey.publicKey

		return try verify(data: data, withSignature: signature, forPublicKey: publicKey.rawRepresentation)
	}

	public static func verify(data: Data, withSignature signature: Data, forPublicKey publicKey: Data) throws -> Bool {
		let pubKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKey)

		return pubKey.isValidSignature(signature, for: data)
	}
}
