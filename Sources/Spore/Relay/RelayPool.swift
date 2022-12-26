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
    func relayPool(_ relayPool: RelayPool, didReceiveEvent event: Event.SignedModel, for subscriptionID: SubscriptionId)
    func relayPool(_ relayPool: RelayPool, didReceiveOkMessage message: Message.Relay.OkMessage)
    func relayPool(_ relayPool: RelayPool, didReceiveOtherMessage message: Message.Relay)
    func relayPool(_ relayPool: RelayPool, didReceiveError error: Error)
}

public final class RelayPool: RelayPoolManaging {
    
    public private(set) var relays: [String: RelayConnectable] = [:]
    
    public weak var delegate: RelayPoolMessagingDelegate?
    
    private let lockQueue = DispatchQueue(label: "NostrSwift.relayPool.lock.queue")
    
    private var pingTimer: Timer?
    
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
        
        // Schedule timer to ping relays to keep them alive
        pingTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { timer in
            self.ping()
        }
    }
    
    public func disconnect() {
        for (_, relay) in relays {
            relay.disconnect()
        }
        
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    public func send(clientMessage: ClientMessageRepresentable) {
        guard !relays.isEmpty else {
            delegate?.relayPool(self, didReceiveError: RelayPoolError.noRelaysAdded)
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
    
    private func ping() {
        for (_, relay) in relays {
            relay.ping()
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
            guard let isValid = try? eventMessage.event.isValid(), isValid else {
                print("Event is not valid. Bailing")
                return
            }
            
            delegate?.relayPool(self, didReceiveEvent: eventMessage.event, for: eventMessage.subscriptionId)
            
        case .notice:
            guard let noticeMessage = relayMessage.message as? Message.Relay.NoticeMessage else {
                print("There was an error decoding the message. Mismatch between type and message")
                return
            }
            print(noticeMessage.message)
            delegate?.relayPool(self, didReceiveOtherMessage: relayMessage)
        case .endOfStoredEvents:
            guard let eoseMessage = relayMessage.message as? Message.Relay.EndOfStoredEventsMessage else {
                print("There was an error decoding the message. Mismatch between type and message")
                return
            }
            print(eoseMessage.subscriptionId)
            delegate?.relayPool(self, didReceiveOtherMessage: relayMessage)
        case .ok:
            guard let okMessage = relayMessage.message as? Message.Relay.OkMessage else {
                print("There was an error decoding the message. Mismatch between type and message")
                return
            }
            print(okMessage.message)
            delegate?.relayPool(self, didReceiveOkMessage: okMessage)
        case .unknown:
            print("Relay message received of unknown type")
        }
    }
    
    public func relayConnection(_ connection: RelayConnection, didReceiveError error: Error) {
        print("Relay-(\(connection.url) : ERROR - \(error.localizedDescription)")
    }    
}
