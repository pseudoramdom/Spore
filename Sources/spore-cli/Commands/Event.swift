import Foundation
import ArgumentParser
import Spore

extension SporeCLI {
    struct Event: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "publish-event", abstract: "subcommand to publish nostr events")
        
        @Argument(help: "PrivateKey hexstring")
        var privateKey: String
        
        @Argument(help: "Kind")
        var kind: Int
        
        @Argument(help: "Content")
        var content: String
        
        func run() throws {
            let keys = try Keys(privateKey: privateKey)
            let kind = Spore.Event.Kind(rawValue: kind)
            let event = try Spore.Event.SignedModel(keys: keys, kind: kind, content: content)
            print("Created event : \(event)")
            
            let semaphore = DispatchSemaphore(value: 0)
            let client = SporeClient()
            bootstrapRelays(for: client)
            sleep(2)
            print("sending...")
            client.send(event)
            client.responseHandler = { response in
                handle(response: response, for: event)
                semaphore.signal()
            }
            semaphore.wait()
        }
        
        private func handle(response: SporeResponse, for event: Spore.Event.SignedModel) {
            guard case let .message(_, message) = response,
                message.type == .ok,
               let info = message.message as? Message.Relay.OkMessage,
               info.eventId == event.id else {
                return
            }
            
            if info.status {
                print("Successfully sent event")
            } else {
                print("Failed to send event - \(info.message)")
            }
        }
    }
}

func bootstrapRelays(for client: SporeClient) {
    
    let bootstrapRelayURLs = [
        "wss://relay.damus.io",
        "wss://nostr-relay.wlvs.space",
        "wss://brb.io",
        "wss://nostr.oxtr.dev",
        "wss://nostr-pub.wellorder.net",
    ]
    
    for urlString in bootstrapRelayURLs {
        let relayUrl = URL(string: urlString)!
        do {
            try client.addRelay(url: relayUrl)
        } catch {
            print("Failed to add relay with URL - \(relayUrl)")
        }
    }
    client.connect()
}
