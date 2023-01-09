import Foundation

private typealias EventsSet = Set<Event.SignedModel>
public typealias SubscriptionEventHandler = (SubscriptionId, Event.SignedModel) -> Void

public enum SporeClientError: Error {
    case invalidSubscriptionIdentifier
}

public final class SporeClient {
    public let keys: Keys
    private var subscriptionsAndEvents: [SubscriptionId: EventsSet] = [:]
    private var subscriptionsAndEventHandlers: [SubscriptionId: SubscriptionEventHandler?] = [:]
    
    private lazy var relayPool = {
        let pool = RelayPool()
        pool.delegate = self
        return pool
    }()
    
    /// Initializes a client with new key pair
    public init() throws {
        self.keys = try Keys()
    }
    
    /// Initializes a client with an existing key pair
    public init(keys: Keys) {
        self.keys = keys
    }
    
    public func addRelay(url: URL) throws {
        let relayConnection = RelayConnection(url: url)
        try relayPool.addRelay(relayConnection)
    }
    
    public func removeRelay(url: URL) throws {
        try relayPool.removeRelay(url: url)
    }    
    
    public func connect() {
        relayPool.connect()
    }
    
    public func disconnect() {
        relayPool.disconnect()
    }
    
    public func send(_ event: Event.SignedModel) {
        guard let isValid = try? event.isValid(), isValid else {
            print("Event is not valid. Check signature")
            return
        }
        
        let eventMessage = Message.Client.EventMessage(event: event)
        relayPool.send(clientMessage: eventMessage)
    }
    
    public func subscribe(_ subscription: Subscription) {
        let subscribeMessage = Message.Client.SubscribeMessage(subscription: subscription)
        relayPool.send(clientMessage: subscribeMessage)
    }
    
    public func unsubscribe(_ subscriptionId: SubscriptionId) {
        let unsubscribeMessage = Message.Client.UnsubscribeMessage(subscriptionId: subscriptionId)
        relayPool.send(clientMessage: unsubscribeMessage)
    }
    
    public func addEventReceiveHandler(for subscriptionId: SubscriptionId, handler: @escaping SubscriptionEventHandler) {
        subscriptionsAndEventHandlers[subscriptionId] = handler
    }
 }

extension SporeClient: RelayPoolMessagingDelegate {
    public func relayPool(_ relayPool: RelayPool, relayURL: URL?, didReceiveEvent event: Event.SignedModel, for subscriptionId: SubscriptionId) {
        print("SporeClient.didReceiveEvent")
        var events = subscriptionsAndEvents[subscriptionId] ?? []
        if !events.contains(event) {
            events.insert(event)
        }
        subscriptionsAndEvents[subscriptionId] = events
        
        if let handler = subscriptionsAndEventHandlers[subscriptionId] {
            handler?(subscriptionId, event)
        }
    }
    
    public func relayPool(_ relayPool: RelayPool, relayURL: URL?, didReceiveOtherMessage message: Message.Relay) {
        switch message.type {
        case .endOfStoredEvents:
            guard let eose = message.message as? Message.Relay.EndOfStoredEventsMessage else {
                return
            }
            print("SporeClient - End of store events for \(eose.subscriptionId)")
            subscriptionsAndEvents.removeValue(forKey: eose.subscriptionId)
            subscriptionsAndEventHandlers.removeValue(forKey: eose.subscriptionId)
        default:
            break
        }
    }
    
    public func relayPool(_ relayPool: RelayPool, relayURL: URL?, didReceiveError error: Error) {
        print("SporeClient.Error:- \(relayURL?.absoluteString ?? "") - \(error.localizedDescription)")
    }
}
