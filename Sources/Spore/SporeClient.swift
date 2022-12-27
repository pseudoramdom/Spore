import Foundation

public struct SubscriptionResult {
    let subscriptionId: String
    let events: [Event.SignedModel]
}

public typealias SubscriptionResultHandler = (Result<SubscriptionResult, Error>) -> Void

private typealias EventsSet = Set<Event.SignedModel>

public final class SporeClient {
    public let keys: Keys
    private var subscriptionsAndEvents: [SubscriptionId: EventsSet] = [:]
    public var subscriptionHandlers: [SubscriptionId: SubscriptionResultHandler] = [:]
    
//    public var eventReceiveHandler: EventReceiveHandler?
    
    private var eventsSendHistory = EventsSet()
    
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
        
        eventsSendHistory.insert(event)
        let eventMessage = Message.Client.EventMessage(event: event)
        relayPool.send(clientMessage: eventMessage)
    }
    
    public func subscribe(_ subscription: Subscription) {
        let subscribeMessage = Message.Client.SubscribeMessage(subscription: subscription)
        relayPool.send(clientMessage: subscribeMessage)
    }
    
    public func subscribe(_ subscription: Subscription,
                          waitAndCompletionHandler completionHandler: @escaping SubscriptionResultHandler) {
        subscribe(subscription)
        subscriptionHandlers[subscription.id] = completionHandler
    }
    
    public func unsubscribe(_ subscriptionId: SubscriptionId) {
        let unsubscribeMessage = Message.Client.UnsubscribeMessage(subscriptionId: subscriptionId)
        relayPool.send(clientMessage: unsubscribeMessage)
    }
}

extension SporeClient: RelayPoolMessagingDelegate {
    public func relayPool(_ relayPool: RelayPool, didReceiveEvent event: Event.SignedModel, for subscriptionID: SubscriptionId) {
        print("SporeClient.didReceiveEvent")
        var events = subscriptionsAndEvents[subscriptionID] ?? []
        if !events.contains(event) {
            events.insert(event)
        }
        subscriptionsAndEvents[subscriptionID] = events
    }
    
    public func relayPool(_ relayPool: RelayPool, didReceiveOkMessage message: Message.Relay.OkMessage) {
        print("SporeClient.didReceiveOkMessage")
        let eventId = message.eventId
        let sentEventFromHistory = eventsSendHistory.filter { event in
            return event.id == eventId
        }.first
        
        if message.status {
            eventReceiveHandler?(.success((nil, nil)))
        } else {
            eventReceiveHandler?(.failure(RelayPoolError.relayError(message: message.message)))
        }
    }
    
    public func relayPool(_ relayPool: RelayPool, didReceiveOtherMessage message: Message.Relay) {
        switch message.type {
        case .endOfStoredEvents:
            guard let eose = message.message as? Message.Relay.EndOfStoredEventsMessage else {
                return
            }
            print("End of store events for \(eose.subscriptionId)")
        default:
            break
        }
    }
    
    public func relayPool(_ relayPool: RelayPool, didReceiveError error: Error) {
        eventReceiveHandler?(.failure(error))
    }
}
