import Foundation

public protocol RelayPoolManaging {
    var relays: [String: RelayConnectable] { get }
    
    func addRelay(_ relay: RelayConnectable) throws
    func removeRelay(url: URL) throws
    
    func connect()
    func disconnect()
    
    /// Send message to relays
    func send(clientMessage: ClientMessageRepresentable)
}

public protocol RelayPoolMessagingDelegate: AnyObject {
    func relayPool(_ relayPool: RelayPool, relayURL: URL?, didReceiveEvent event: Event.SignedModel, for subscriptionID: SubscriptionId)
    func relayPool(_ relayPool: RelayPool, relayURL: URL?, didReceiveOtherMessage message: Message.Relay)
    func relayPool(_ relayPool: RelayPool, relayURL: URL?, didReceiveError error: Error)
}

public final class RelayPool: RelayPoolManaging {
    
    public private(set) var relays: [String: RelayConnectable] = [:]
    
    public weak var delegate: RelayPoolMessagingDelegate?
    
    private let lockQueue = DispatchQueue(label: "Spore.relayPool.lock.queue")
    
    public func addRelay(_ relay: RelayConnectable) throws {
        var relay = relay
        
        let url = relay.url
        guard !containsRelay(url: url) else {
            print("Relay with url \(url.absoluteString) already exists")
            throw RelayPoolError.relayAlreadyExists
        }
        
        relay.delegate = self
        
        return lockQueue.sync { [unowned self] in
            self.relays[url.absoluteString] = relay
        }
    }
    
    public func removeRelay(url: URL) throws {
        guard containsRelay(url: url) else {
            print("Failed to remove Relay. No relay exists with url \(url.absoluteString).")
            throw RelayPoolError.relayDoesNotExist
        }
        
        let relay = self.relays[url.absoluteString]
        relay?.disconnect()
        
        return lockQueue.sync { [unowned self] in
            self.relays.removeValue(forKey: url.absoluteString)
        }
    }
    
    public func connect() {
        for (_, relay) in relays {
            relay.connect()
        }
    }
    
    public func disconnect() {
        for (_, relay) in relays {
            relay.disconnect()
        }
    }
    
    public func send(clientMessage: ClientMessageRepresentable) {
        guard !relays.isEmpty else {
            delegate?.relayPool(self, relayURL: nil, didReceiveError: RelayPoolError.noRelaysAdded)
            return
        }
        for (_, relay) in relays {
            guard relay.isOpen else {
                print("Relay (\(relay.url) is not connected")
                continue
            }
            relay.send(clientMessage: clientMessage)
        }
    }
    
    deinit {
        print("Deinit RelayPool")
    }
}

extension RelayPool {
    private func containsRelay(url: URL) -> Bool {
        return relays.keys.contains(url.absoluteString)
    }
}

extension RelayPool: RelayConnectionDelegate {
    public func relayConnectionDidConnect(_ connection: RelayConnection) {
        print("Relay-(\(connection.url) connected")
    }
    
    public func relayConnectionDidDisconnect(_ connection: RelayConnection) {
        try? removeRelay(url: connection.url)
    }
    
    public func relayConnection(_ connection: RelayConnection, didReceiveMessage relayMessage: Message.Relay) {
        print("RelayPool.relayConnectionDidReceiveMessage")
        
        switch relayMessage.type {
        case .event:
            guard let eventMessage = relayMessage.message as? Message.Relay.EventMessage else {
                print("There was an error decoding the message. Mismatch between type and message")
                return
            }
            
            // TODO: Reenable after fixing event validity check
//            guard let isValid = try? eventMessage.event.isValid(), isValid else {
//                print("Event is not valid. Bailing")
//                return
//            }
            
            delegate?.relayPool(self, relayURL: nil, didReceiveEvent: eventMessage.event, for: eventMessage.subscriptionId)
            
        case .notice, .endOfStoredEvents, .ok:
            delegate?.relayPool(self, relayURL: connection.url, didReceiveOtherMessage: relayMessage)
        case .unknown:
            print("Relay message received of unknown type")
        }
    }
    
    public func relayConnection(_ connection: RelayConnection, didReceiveError error: Error) {
        print("Relay-(\(connection.url) : ERROR - \(error.localizedDescription)")
        delegate?.relayPool(self, relayURL: connection.url, didReceiveError: error)
    }    
}
