import Foundation
import secp256k1

public enum KeysError: Error {
    case invalidHexString
}

public struct Keys {
    public typealias PrivateKey = secp256k1.Signing.PrivateKey
    public  typealias PublicKey = secp256k1.Signing.PublicKey
    public typealias KeySchnorrSigner = secp256k1.Signing.SchnorrSigner
    public typealias KeySchnorrValidator = secp256k1.Signing.SchnorrValidator
    
    public let privateKey: PrivateKey
    
    public init() throws {
        self.privateKey = try PrivateKey()
    }
    
    public init(privateKey: Data) throws {
        self.privateKey = try PrivateKey(rawRepresentation: privateKey)
    }
    
    public init(privateKey: String) throws {
        let keyData = try Data(hexString: privateKey)
        try self.init(privateKey: keyData)
    }
    
    public var publicKey: String {
        return Data(privateKey.publicKey.xonly.bytes).hexEncodedString
    }
    
    public var schnorrSigner: KeySchnorrSigner {
        return privateKey.schnorr
    }
    
    public var schnorrValidator: KeySchnorrValidator {
        return privateKey.publicKey.schnorr
    }
}
