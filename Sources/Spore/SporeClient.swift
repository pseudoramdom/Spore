import Foundation

public typealias EventsSet = Set<Event.SignedModel>
public typealias EventReceiveHandler = (Result<(SubscriptionId?, Event.SignedModel?), Error>) -> Void

public final class SporeClient {
    public let keys: Keys
    public var subscriptionsAndEvents: [SubscriptionId: EventsSet] = [:]
    public var eventReceiveHandler: EventReceiveHandler?
    
    private var eventsSendHistory = Set<Event.SignedModel>()
    
    private lazy var relayPool = {
        let pool = RelayPool()
        pool.delegate = self
        return pool
    }()
    
    public init() throws {
        self.keys = try Keys()
        let pool = RelayPool()
        pool.delegate = self
    }
    
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
    
    public func send(_ event: Event.SignedModel) {
        guard let isValid = try? event.isValid(), isValid else {
            print("Event is not valid. Check signature")
            return
        }
        
        eventsSendHistory.insert(event)
        let eventMessage = Message.Client.EventMessage(event: event)
        relayPool.send(clientMessage: eventMessage)
    }
    
    public func connect() {
        relayPool.connect()
    }
    
    public func disconnect() {
        relayPool.disconnect()
    }
    
    public func subscribe(_ subscription: Subscription) {
        let subscribeMessage = Message.Client.SubscribeMessage(subscription: subscription)
        relayPool.send(clientMessage: subscribeMessage)
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
            eventReceiveHandler?(.success((subscriptionID, event)))
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
        
    }
    
    public func relayPool(_ relayPool: RelayPool, didReceiveError error: Error) {
        eventReceiveHandler?(.failure(error))
    }
}
