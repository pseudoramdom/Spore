import Foundation
import ArgumentParser
import Spore

extension SporeCLI {
    struct Subscribe: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "subscribe",
                                                        abstract: "subcommand to subscribe to events based on filters - author, tags, etc")
        
        @Option(name: [.customShort("a"), .long], help: "list of authors' pubkey")
        var authors: [String] = []
        
        func run() throws {
            let keys = try Keys(privateKey: "aa3b75b54ca8e05db208b11e97b4bc6abd4e432abaf96c6f46c2cda955063d3e")
            let filter = Filter(authors:authors)
            try subscribe(keys: keys, filter: filter)
        }
        
        func subscribe(keys: Keys, filter: Filter) throws {
            let subscription = Subscription(id: UUID().uuidString, filters: [filter])

            let semaphore = DispatchSemaphore(value: 0)
            let client = SporeClient(keys: keys)
            
            let relayUrl = URL(string: "wss://nostr-pub.wellorder.net")!
            try client.addRelay(url: relayUrl)
            
            client.connect()
            sleep(2)
            print("sending...")
            
            client.eventReceiveHandler = { result in
                switch result {
                case .failure(let error):
                    print("Received error from client - \(error.localizedDescription)")
                case .success(let response):
                    print("Received response - \(response)")
                }
                semaphore.signal()
            }
            client.subscribe(subscription)
            semaphore.wait()
        }
    }
}
