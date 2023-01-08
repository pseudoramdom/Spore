import Foundation
import ArgumentParser
import Spore

extension SporeCLI {
    struct Subscribe: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "subscribe",
                                                        abstract: "subcommand to subscribe to events based on filters - author, tags, etc")
        
        @Option(name: [.customShort("a"), .long],
                help: "a list of pubkeys or prefixes, the pubkey of an event must be one of these")
        var authors: [String] = []
        
        @Option(name: [.customShort("k"), .long],
                help: "a list of a kind numbers")
        var kinds: [Int] = []
        
        @Option(name: [.customShort("h"), .long],
                help: "a list of hashtags")
        var hashtags: [String] = []
        
        @Option(name: [.customShort("r"), .long],
                help: "a list of reference tags")
        var referenceTags: [String] = []
        
        @Option(name: [.customShort("g"), .long],
                help: "a list of reference tags")
        var geoTags: [String] = []
        
        @Option(help: "filter since mentioned timestamp")
        var since: TimeInterval?
        
        @Option(help: "filter until mentioned timestamp")
        var until: TimeInterval?
        
        @Option(help: "limit number of events returned")
        var limit: Int?
        
        func run() throws {
            let keys = try Keys(privateKey: "aa3b75b54ca8e05db208b11e97b4bc6abd4e432abaf96c6f46c2cda955063d3e")
            let filter = Filter(authors:authors.isEmpty ? nil : authors,
                                kinds: kinds.isEmpty ? nil : kinds,
                                hashtags: hashtags.isEmpty ? nil : hashtags,
                                geoTags: geoTags.isEmpty ? nil : geoTags,
                                referenceTags: referenceTags.isEmpty ? nil : referenceTags,
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
            
            SporeSDK.client.addEventReceiveHandler(for: subscription.id) { subscriptionId, event in
                guard subscriptionId == subscription.id else {
                    print("Received unrelated event. Ignoring...")
                    return
                }
                print("RECEIVED - \(subscriptionId)\n\(event)")
            }
            
            SporeSDK.client.subscribe(subscription)
            semaphore.wait()
        }
    }
}
