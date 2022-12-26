import Foundation


public protocol ClientMessageRepresentable: Encodable {
    var type: Message.Client.MessageType { get }
    
    func encodedString() throws -> String
}

extension ClientMessageRepresentable {
    public func encodedString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }
}

extension Message {
    /// Message types that a client can send to a relay
    ///
    /// Ref: [Message Types](https://github.com/nostr-protocol/nips#client-to-relay)
    public enum Client{
        public typealias MessageType = String
    }
}

extension Message.Client {
    /// Used to publish events
    public struct EventMessage: ClientMessageRepresentable {
        public let type = "EVENT"
        
        public let event: Event.SignedModel
        
        public init(event: Event.SignedModel) {
            self.event = event
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(type)
            try container.encode(event)
        }
    }
}

extension Message.Client {
    /// Message used to subscribe to authors, events, tags etc.
    public struct SubscribeMessage: ClientMessageRepresentable {
        
        public let type = "REQ"
        
        public let subscription: Subscription
        
        public init(subscription: Subscription) {
            self.subscription = subscription
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(type)
            try subscription.encode(to: encoder)
        }
    }
}

extension Message.Client {
    /// Message used to unsubscribe
    public struct UnsubscribeMessage: ClientMessageRepresentable {
        
        public let type = "CLOSE"
        
        public let subscriptionId: SubscriptionId
        
        public init(subscriptionId: String) {
            self.subscriptionId = subscriptionId
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(type)
            try container.encode(subscriptionId)
        }
    }
}

