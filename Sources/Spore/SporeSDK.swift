import Foundation

public class SporeSDK {
    
    public static var client: SporeClient!
    
    public static func initializeNewClient() throws {
        client = try SporeClient()
        bootstrapRelays(for: client)
    }
    
    public static func initializeClient(with keys: Keys) {
        client = SporeClient(keys: keys)
        bootstrapRelays(for: client)
    }
    
    private init() {}
}

extension SporeSDK {
    static let bootstrapRelayURLs = [
        "wss://relay.damus.io",
        "wss://nostr-relay.wlvs.space",
        "wss://brb.io",
        "wss://nostr.oxtr.dev",
        "wss://nostr-pub.wellorder.net",
    ]
    
    private static func bootstrapRelays(for client: SporeClient) {
        for urlString in SporeSDK.bootstrapRelayURLs {
            let relayUrl = URL(string: urlString)!
            do {
                try client.addRelay(url: relayUrl)
            } catch {
                print("Failed to add relay with URL - \(relayUrl)")
            }
        }
        client.connect()
    }
}

extension SporeSDK {
    public static func getCurrentUserContacts(subscriptionId: String = UUID().uuidString, for client: SporeClient = client) {
        Self.getFollowingContacts(publicKey: client.keys.publicKey, subscriptionId: subscriptionId)
    }
    
    public static func getFollowingContacts(publicKey: String,
                                            subscriptionId: String = UUID().uuidString,
                                            for client: SporeClient = client) {
        let filter = Filter(authors:[publicKey], kinds: [Event.Kind.contactList.rawValue])
        let subscriptionId = subscriptionId
        let subscription = Subscription(id: subscriptionId, filters: [filter])
        
        client.subscribe(subscription)
    }
}

extension SporeSDK {
    public static func updateCurrentUserProfile(metadata: Metadata, for client: SporeClient = client) throws {
        let jsonEncodedString = try metadata.encodedString()
        let event = try Event.SignedModel(keys: client.keys, kind: .setMetadata, content: jsonEncodedString)
        client.send(event)
    }
    
    public static func getCurrentUserProfile(subscriptionId: String = UUID().uuidString,
                                             for client: SporeClient = client) async throws -> Metadata {
        return try await getUserProfile(publicKey: client.keys.publicKey)
    }
    
    public static func getUserProfile(publicKey: String,
                                      subscriptionId: String = UUID().uuidString,
                                      for client: SporeClient = client) async throws -> Metadata {
        let filter = Filter(authors:[publicKey], kinds: [Event.Kind.setMetadata.rawValue])
        let subscriptionId = subscriptionId
        let subscription = Subscription(id: subscriptionId, filters: [filter])
        
        client.subscribe(subscription)
        return try await withCheckedThrowingContinuation({ continuation in
            client.addEventReceiveHandler(for: subscriptionId) { subId, event in
                guard subId == subscriptionId else {
                    print("Received unrelated event. Ignoring...")
                    continuation.resume(throwing: SporeClientError.invalidSubscriptionIdentifier)
                    return
                }
                
                do {
                    let jsonData = Data(event.content.utf8)
                    let metadata = try JSONDecoder().decode(Metadata.self, from: jsonData)
                    continuation.resume(returning: metadata)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        })
        
    }
}


