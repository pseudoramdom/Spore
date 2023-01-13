import Foundation
import secp256k1

/**
 Describes an event
 
 Event is the only object type in the protocol spec.
 Ref: [NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md)
 
 A typical event from a relay response might looks like this
 ```json
 {
 "id": <32-bytes sha256 of the the serialized event data>
 "pubkey": <32-bytes hex-encoded public key of the event creator>,
 "created_at": <unix timestamp in seconds>,
 "kind": <integer>,
 "tags": [
 ["e", <32-bytes hex of the id of another event>, <recommended relay URL>],
 ["p", <32-bytes hex of the key>, <recommended relay URL>],
 ... // other kinds of tags may be included later
 ],
 "content": <arbitrary string>,
 "sig": <64-bytes signature of the sha256 hash of the serialized event data, which is the same as the "id" field>
 }
 ```
 */
public enum Event {}

extension Event {
    
    /// Describes an event that is signed by the creator of the event.
    public struct SignedModel: Codable {
        
        /// 32-bytes sha256 of the the serialized event data
        public let id: String
        
        /// 32-bytes hex-encoded public key of the event creator
        public let publicKey: String
        
        /// unix timestamp in seconds
        public let createdAt: Int64
        
        /// Event kind
        public let kind: Event.Kind
        
        /// Event tags
        public let tags: [Event.Tag]
        
        /// Any arbitrary string
        public let content: String
        
        /// 64-bytes signature of the sha256 hash of the serialized event data, which is the same as the "id" field
        public let signature: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case publicKey = "pubkey"
            case createdAt = "created_at"
            case kind
            case tags
            case content
            case signature = "sig"
        }
    }
}

extension Event.SignedModel {
    /// Creates a new signed event using the key pair
    public init(keys: Keys,
                kind: Event.Kind,
                tags: [Event.Tag] = [],
                content: String) throws {
        
        self.publicKey = keys.publicKey
        self.createdAt = Int64(Date().timeIntervalSince1970)
        self.kind = kind
        self.tags = tags
        self.content = content
        
        let serializableEvent = Event.SerializableModel(publicKey: publicKey,
                                                        createdAt: createdAt,
                                                        kind: kind,
                                                        tags: tags,
                                                        content: content)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let serializedEvent = try encoder.encode(serializableEvent)
            let sha256Serialized = SHA256.hash(data: serializedEvent)
            self.id = Data(sha256Serialized).hexEncodedString
            
            let sig = try keys.schnorrSigner.signature(for: sha256Serialized)
            guard keys.schnorrValidator.isValidSignature(sig, for: sha256Serialized) else {
                throw Event.EventError.signingFailed
            }
            
            self.signature = sig.rawRepresentation.hexEncodedString
        } catch is EncodingError {
            throw Event.EventError.encodingFailed
        } catch {
            throw Event.EventError.signingFailed
        }
    }
}

extension Event.SignedModel {
    
    private func serializedEvent() throws -> Data {
        let serializableEvent = Event.SerializableModel(publicKey: publicKey,
                                                        createdAt: createdAt,
                                                        kind: kind,
                                                        tags: tags,
                                                        content: content)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let serializedEvent = try encoder.encode(serializableEvent)
            return serializedEvent
        } catch is EncodingError {
            throw Event.EventError.encodingFailed
        } catch {
            throw error
        }
    }
    
    private func generateEventIdData(serializedEvent: Data) throws -> Data {
        return Data(SHA256.hash(data: serializedEvent))
    }
    
    public func isValid() throws -> Bool {
        print("checking eventID validity")
        
        let sha256Serialized = try SHA256.hash(data: serializedEvent())
        let calculatedEventId = Data(sha256Serialized).hexEncodedString
        
        guard calculatedEventId == id else {
            print("Invalid event ID")
            throw Event.EventError.invalidEventId
        }
        
        print("Event ID is valid.")
        
        // TODO: Clean this up with the new initializer
        // https://github.com/GigaBitcoin/secp256k1.swift/pull/239/files
        // Also discussed in https://github.com/GigaBitcoin/secp256k1.swift/issues/269
//        let keyParity = true
//        let xOnlyKeyBytes = try publicKey.bytes
//        let yCoord: [UInt8] = keyParity ? [3] : [2]
//        let pubKeyBytes = yCoord + xOnlyKeyBytes
        
        let xOnlyKey = try secp256k1.Signing.XonlyKey(rawRepresentation: publicKey.bytes, keyParity: 1)
        let pubKey = secp256k1.Signing.PublicKey(xonlyKey: xOnlyKey)
        
        let schnorrSignature = try secp256k1.Signing.SchnorrSignature(rawRepresentation: signature.bytes)
        
        guard pubKey.schnorr.isValidSignature(schnorrSignature, for: sha256Serialized) else {
            throw Event.EventError.invalidSignature
        }
        
        print("Signature is valid")
        return true
    }
}

extension Event.SignedModel: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var hashValue: Int {
        return id.hashValue
    }
    
    public static func == (lhs: Event.SignedModel, rhs: Event.SignedModel) -> Bool {
        return lhs.id == rhs.id
    }
}
