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
        "wss://nostr.fmt.wiz.biz",
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
    public static func updateProfile(metadata: Metadata, for client: SporeClient = client) throws {
        let jsonEncodedString = try metadata.encodedString()
        let event = try Event.SignedModel(keys: client.keys, kind: .setMetadata, content: jsonEncodedString)
        client.send(event)
    }
    
    public static func getProfile(publicKey: String,
                                  subscriptionId: String = UUID().uuidString,
                                  for client: SporeClient = client) throws {
        let filter = Filter(authors:[publicKey], kinds: [Event.Kind.setMetadata.rawValue])
        let subscriptionId = subscriptionId
        let subscription = Subscription(id: subscriptionId, filters: [filter])
        
        client.subscribe(subscription)
    }
}


