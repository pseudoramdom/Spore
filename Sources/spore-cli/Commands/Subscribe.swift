import Foundation
import ArgumentParser
import Spore

extension SporeCLI {
    struct Subscribe: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "subscribe",
                                                        abstract: "subcommand to subscribe to events based on filters - author, tags, etc")
        
        @Option(name: [.customShort("a"), .long],
                help: "a list of pubkeys or prefixes, the pubkey of an event must be one of these")
        var authors: [String]
        
        @Option(name: [.customShort("k"), .long],
                help: "a list of a kind numbers")
        var kinds: [Int]
        
        @Option(help: "filter since mentioned timestamp")
        var since: TimeInterval?
        
        @Option(help: "filter until mentioned timestamp")
        var until: TimeInterval?
        
        @Option(help: "limit number of events returned")
        var limit: Int?
        
        func run() throws {
            let keys = try Keys(privateKey: "aa3b75b54ca8e05db208b11e97b4bc6abd4e432abaf96c6f46c2cda955063d3e")
            let filter = Filter(authors:authors,
                                kinds: kinds,
                                since: since,
                                until: until,
                                limit: limit)
            try subscribe(keys: keys, filter: filter)
        }
        
        func subscribe(keys: Keys, filter: Filter) throws {
            let subscription = Subscription(id: UUID().uuidString, filters: [filter])

            let semaphore = DispatchSemaphore(value: 0)
            SporeSDK.initializeClient(with: keys)
            
            sleep(2)
            print("sending...")
            
            SporeSDK.client.eventReceiveHandler = { result in
                switch result {
                case .failure(let error):
                    print("Received error from client - \(error.localizedDescription)")
                case .success(let response):
                    print("Received response - \(response)")
                }
//                semaphore.signal()
            }
            SporeSDK.client.subscribe(subscription)
            semaphore.wait()
        }
    }
}
