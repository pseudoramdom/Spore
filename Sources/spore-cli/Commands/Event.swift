import Foundation
import ArgumentParser
import Spore

extension SporeCLI {
    struct Event: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "publish-event", abstract: "subcommand to publish nostr events", subcommands: [TextNote.self])
    }
}

extension SporeCLI.Event {
    struct TextNote: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "text-note",
                                                        abstract: "Creates a new text note")
        
        @Argument(help: "Content of the text note")
        var text: String
        
        func run() throws {
            let keys = try Keys(privateKey: "aa3b75b54ca8e05db208b11e97b4bc6abd4e432abaf96c6f46c2cda955063d3e")
            try newPost(keys: keys, text: text)
        }
        
        private func newPost(keys: Keys, text: String) throws {
            let event = try Event.SignedModel(keys: keys, kind: .textNote, content: text)
            print("Created event : \(event)")
            
            let semaphore = DispatchSemaphore(value: 0)
            let client = SporeClient(keys: keys)
            
            let relayUrl = URL(string: "wss://nostr-pub.wellorder.net")!
            try client.addRelay(url: relayUrl)
            
            client.connect()
            sleep(2)
            print("sending...")
            client.send(event)
            semaphore.wait()
        }
    }
}

extension SporeCLI.Event {
    struct SetMetadata: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "set-metadata",
                                                        abstract: "Creates a new text note")
        
        @Argument(help: "Content of the text note")
        var text: String
        
        func run() throws {
            let keys = try Keys(privateKey: "aa3b75b54ca8e05db208b11e97b4bc6abd4e432abaf96c6f46c2cda955063d3e")
            try newPost(keys: keys, text: text)
        }
        
        private func newPost(keys: Keys, text: String) throws {
            let event = try Event.SignedModel(keys: keys, kind: .textNote, content: text)
            print("Created event : \(event)")
            
            let semaphore = DispatchSemaphore(value: 0)
            let client = SporeClient(keys: keys)
            
            let relayUrl = URL(string: "wss://nostr-pub.wellorder.net")!
            try client.addRelay(url: relayUrl)
            
            client.connect()
            sleep(2)
            print("sending...")
            client.send(event)
            semaphore.wait()
        }
    }
}
