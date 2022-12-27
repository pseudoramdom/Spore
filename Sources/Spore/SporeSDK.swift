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
    public static func getFollowingContacts(for client: SporeClient = client) -> Event.SignedModel {
        let filter = Filter(authors:[client.keys.publicKey], kinds: [Event.Kind.contactList.rawValue])
        let subscriptionId = UUID().uuidString
        let subscription = Subscription(id: subscriptionId, filters: [filter])
        
        client.subscribe(subscription)
        
    }
}


