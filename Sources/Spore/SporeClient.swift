import Foundation

public struct SubscriptionResult {
    let subscriptionId: String
    let events: [Event.SignedModel]
}

private typealias EventsSet = Set<Event.SignedModel>
private typealias SubscriptionEventsContinuation = CheckedContinuation<SubscriptionResult, Error>

public final class SporeClient {
    public let keys: Keys
    
    private var subscriptionsAndEvents: [SubscriptionId: EventsSet] = [:]
    private var subscriptionsAndContinuations: [SubscriptionId: SubscriptionEventsContinuation] = [:]
    
//    public var eventReceiveHandler: EventReceiveHandler?
    
    private var eventsSendHistory = EventsSet()
    
    private lazy var relayPool = {
        let pool = RelayPool()
//        pool.delegate = self
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
        Task {
            try await relayPool.addRelay(relayConnection)
        }
    }
    
    public func removeRelay(url: URL) throws {
        Task {
            try await relayPool.removeRelay(url: url)
        }   
    }
    
    public func send(_ event: Event.SignedModel) async {
        guard let isValid = try? event.isValid(), isValid else {
            print("Event is not valid. Check signature")
            return
        }
        
        eventsSendHistory.insert(event)
        let eventMessage = Message.Client.EventMessage(event: event)
        await relayPool.send(clientMessage: eventMessage)
    }
    
    public func subscribe(_ subscription: Subscription) async {
        let subscribeMessage = Message.Client.SubscribeMessage(subscription: subscription)
        await relayPool.send(clientMessage: subscribeMessage)
    }
    
    public func subscribeAndWaitForEvents(_ subscription: Subscription) async throws -> SubscriptionResult {
        let subscribeMessage = Message.Client.SubscribeMessage(subscription: subscription)
        Task {
            await relayPool.send(clientMessage: subscribeMessage)
        }
        
        return try await withCheckedThrowingContinuation({ (continuation: SubscriptionEventsContinuation) in
            var subscriptionEventContinuation: SubscriptionEventsContinuation = continuation
            self.subscriptionsAndContinuations[subscription.id] = subscriptionEventContinuation
        })
    }
    
    public func unsubscribe(_ subscriptionId: SubscriptionId) async {
        let unsubscribeMessage = Message.Client.UnsubscribeMessage(subscriptionId: subscriptionId)
        await relayPool.send(clientMessage: unsubscribeMessage)
    }
}

extension SporeClient: RelayPoolMessagingDelegate {
    public func relayPool(_ relayPool: RelayPool, didReceiveEOSEMessage message: Message.Relay.EndOfStoredEventsMessage) {
        
    }
    
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
//            eventReceiveHandler?(.success((nil, nil)))
        } else {
//            eventReceiveHandler?(.failure(RelayPoolError.relayError(message: message.message)))
        }
    }
    
    public func relayPool(_ relayPool: RelayPool, didReceiveOtherMessage message: Message.Relay) {
        switch message.type {
        case .endOfStoredEvents:
            guard let eose = message.message as? Message.Relay.EndOfStoredEventsMessage else {
                return
            }
            print("End of store events for \(eose.subscriptionId)")
            if let continuation = subscriptionsAndContinuations[eose.subscriptionId] {
                let events = subscriptionsAndEvents[eose.subscriptionId] ?? []
                let result = SubscriptionResult(subscriptionId: eose.subscriptionId,
                                                events: Array(events))
                continuation.resume(returning: result)
            }
        default:
            break
        }
    }
    
    public func relayPool(_ relayPool: RelayPool, didReceiveError error: Error) {
//        eventReceiveHandler?(.failure(error))
    }
}
