import Foundation

public protocol RelayPoolMessagingDelegate: AnyObject {
    func relayPool(_ relayPool: RelayPool, didReceiveEvent event: Event.SignedModel, for subscriptionID: SubscriptionId)
    func relayPool(_ relayPool: RelayPool, didReceiveOkMessage message: Message.Relay.OkMessage)
    func relayPool(_ relayPool: RelayPool, didReceiveEOSEMessage message: Message.Relay.EndOfStoredEventsMessage)
    func relayPool(_ relayPool: RelayPool, didReceiveOtherMessage message: Message.Relay)
    func relayPool(_ relayPool: RelayPool, didReceiveError error: Error)
}

public typealias RelayURL = String

public actor RelayPool {
    
    public private(set) var relays: [RelayURL: RelayConnection] = [:]
    
    public private(set) weak var delegate: RelayPoolMessagingDelegate?
    
    public func addRelay(_ relay: RelayConnection) throws {
        let url = relay.url
        guard !containsRelay(url: url) else {
            print("Relay with url \(url.absoluteString) already exists")
            throw RelayPoolError.relayAlreadyExists
        }
        
        self.relays[url.absoluteString] = relay
    }
    
    public func removeRelay(url: URL) throws {
        guard containsRelay(url: url) else {
            print("Failed to remove Relay. No relay exists with url \(url.absoluteString).")
            throw RelayPoolError.relayDoesNotExist
        }
        
        let relay = self.relays[url.absoluteString]
        relay?.disconnect()
        
        self.relays.removeValue(forKey: url.absoluteString)
    }
    
    public func disconnect() {
        for (_, relay) in relays {
            relay.disconnect()
        }
    }
    
    public func send(clientMessage: ClientMessageRepresentable) async {
        guard !relays.isEmpty else {
            await delegate?.relayPool(self, didReceiveError: RelayPoolError.noRelaysAdded)
            return
        }
        for (_, relay) in relays {
            do {
                try await relay.send(clientMessage: clientMessage)
            } catch {
                print("Send error with relay: \(relay.url)")
            }
        }
    }
    
    public func receiveEvents() async {
        for (_, relay) in relays {
            Task.detached {
                for try await message in relay {
                    await self.handle(relayMessage: message)
                }
            }
        }
    }
    
    public nonisolated func setDelegate(_ delegate: RelayPoolMessagingDelegate) {
        self.delegate = delegate
    }
    
    deinit {
        print("Deinit RelayPool")
    }
}

extension RelayPool {
    private func containsRelay(url: URL) -> Bool {
        return relays.keys.contains(url.absoluteString)
    }
    
    private func handle(relayMessage: Message.Relay) {
        print("RelayPool.handleRelayMessage")
        
        switch relayMessage.type {
        case .event:
            guard let eventMessage = relayMessage.message as? Message.Relay.EventMessage else {
                print("There was an error decoding the message. Mismatch between type and message")
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
            delegate?.relayPool(self, didReceiveEOSEMessage: eoseMessage)
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
}
