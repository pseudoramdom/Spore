import Foundation

public protocol EventTagInfoRepresentable: Codable {}
public extension Event {
    struct Tag: Codable {
        public let type: TagType
        public let info: EventTagInfoRepresentable
    }
}

public extension Event.Tag {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let type = try container.decode(TagType.self)
        self.type = type
        switch type.rawValue {
        case TagType.event.rawValue:
            self.info = try EventInfo(from: container)
        case TagType.publicKey.rawValue:
            self.info = try PublicKeyInfo(from: container)
        case TagType.nonce.rawValue:
            self.info = try NonceInfo(from: container)
        case TagType.delegation.rawValue:
            self.info = try DelegationInfo(from: container)
        default:
            self.info = try GenericInfo(from: container)
        }
    }
    
    init(data: Data) throws {
        self = try JSONDecoder().decode(Event.Tag.self, from: data)
    }
}

public extension Event.Tag {
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(type)
        try container.encode(info)
    }
}

public extension Event.Tag {
    
    struct GenericInfo: EventTagInfoRepresentable {
        public let info: [String]
        
        public init(from container: UnkeyedDecodingContainer) throws {
            var container = container
            var infoArray = [String]()
            while !container.isAtEnd {
                let item = try container.decode(String.self)
                infoArray.append(item)
            }
            
            self.info = infoArray
        }
    }
    
    struct EventInfo: EventTagInfoRepresentable {
        public let eventId: String
        public let recommendedRelayURL: String?
        
        public init(from container: UnkeyedDecodingContainer) throws {
            var container = container
            self.eventId = try container.decode(String.self)
            self.recommendedRelayURL = try container.decodeIfPresent(String.self)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(eventId)
            if let recommendedRelayURL = recommendedRelayURL {
                try container.encode(recommendedRelayURL)
            }
        }
    }
    
    struct PublicKeyInfo: EventTagInfoRepresentable {
        public let publicKeyHexString: String
        public let recommendedRelayURL: String?
        
        public init(from container: UnkeyedDecodingContainer) throws {
            var container = container
            self.publicKeyHexString = try container.decode(String.self)
            self.recommendedRelayURL = try container.decodeIfPresent(String.self)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(publicKeyHexString)
            if let recommendedRelayURL = recommendedRelayURL {
                try container.encode(recommendedRelayURL)
            }
        }
    }
    
    struct NonceInfo: EventTagInfoRepresentable {
        public let desiredLeadingZeroes: String
        public let targetDifficulty: String
        
        public init(from container: UnkeyedDecodingContainer) throws {
            var container = container
            self.desiredLeadingZeroes = try container.decode(String.self)
            self.targetDifficulty = try container.decode(String.self)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(desiredLeadingZeroes)
            try container.encode(targetDifficulty)
        }
    }
    
    struct DelegationInfo: EventTagInfoRepresentable {
        /// pubkey of the delegator
        public let publicKey: String
        
        /// conditions query string
        public let conditionsQuery: String
        
        /// 64-bytes schnorr signature of the sha256 hash of the delegation token
        public let signature: String
        
        public init(from container: UnkeyedDecodingContainer) throws {
            var container = container
            self.publicKey = try container.decode(String.self)
            self.conditionsQuery = try container.decode(String.self)
            self.signature = try container.decode(String.self)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(publicKey)
            try container.encode(conditionsQuery)
            try container.encode(signature)
        }
    }
}
