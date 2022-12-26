import Foundation

public protocol RelayMessageRepresentable: Decodable {}

extension Message {
    
    /// Message received from a relay that a client can consume
    public struct Relay: Decodable {
        public let type: RelayMessageType
        public let message: RelayMessageRepresentable
        
        public init(type: RelayMessageType, message: RelayMessageRepresentable) {
            self.type = type
            self.message = message
        }
    }
}

extension Message.Relay {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        self.type = try container.decode(RelayMessageType.self)
        
        switch type {
        case .event:
            self.message = try EventMessage(from: container)
        case .notice:
            self.message = try NoticeMessage(from: container)
        case .endOfStoredEvents:
            self.message = try EndOfStoredEventsMessage(from: container)
        case .ok:
            self.message = try OkMessage(from:container)
        case .unknown:
            throw Message.MessageError.decodingFailed
        }
    }
    
    /// Creates a `Message.Relay` from data
    public init(data: Data) throws {
        self = try JSONDecoder().decode(Message.Relay.self, from: data)
    }
}

extension Message.Relay {
    /// Message types that a relay can send to a client
    ///
    /// Ref: [Message Types](https://github.com/nostr-protocol/nips#client-to-relay)
    public enum RelayMessageType: String, Decodable {
        /// Used to send events requested to clients
        case event = "EVENT"
        
        /// Used to send human-readable messages to clients
        case notice = "NOTICE"
        
        /// Used to notify clients all stored events have been sent
        case endOfStoredEvents = "EOSE"
        
        /// Used to notify clients if an EVENT was successful
        case ok = "OK"
        
        /// Unknown Relay message type.
        case unknown
    }
}

// MARK: Concrete reply message types

extension Message.Relay {
    public struct EventMessage: RelayMessageRepresentable {
        public let subscriptionId: String
        public let event: Event.SignedModel
        
        public init(from container: UnkeyedDecodingContainer) throws {
            var container = container
            self.subscriptionId = try container.decode(String.self)
            self.event = try container.decode(Event.SignedModel.self)
        }
    }
}

extension Message.Relay {
    public struct NoticeMessage: RelayMessageRepresentable {
        public let message: String
        
        public init(from container: UnkeyedDecodingContainer) throws {
            var container = container
            self.message = try container.decode(String.self)
        }
    }
}

extension Message.Relay {
    public struct EndOfStoredEventsMessage: RelayMessageRepresentable {
        public let subscriptionId: String
        
        public init(from container: UnkeyedDecodingContainer) throws {
            var container = container
            self.subscriptionId = try container.decode(String.self)
        }
    }
}

extension Message.Relay {
    public struct OkMessage: RelayMessageRepresentable {
        public let eventId: String
        public let status: Bool
        public let message: String
        
        public init(from container: UnkeyedDecodingContainer) throws {
            var container = container
            
            self.eventId = try container.decode(String.self)
            self.status = try container.decode(Bool.self)
            self.message = try container.decode(String.self)
        }
    }
}

