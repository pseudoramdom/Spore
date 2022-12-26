import Foundation

public extension Event {
    struct SerializableModel: Encodable {
        let id = 0
        let publicKey: String
        let createdAt: Int64
        let kind: Event.Kind
        let tags: [Event.Tag]
        let content: String
        
        private enum CodingKeys: String, CodingKey {
            case id
            case publicKey = "pubkey"
            case createdAt = "created_at"
            case kind
            case tags
            case content
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(id)
            try container.encode(publicKey)
            try container.encode(createdAt)
            try container.encode(kind)
            try container.encode(tags)
            try container.encode(content)
        }
    }
}
