import Foundation
import ArgumentParser
import Spore

extension SporeCLI {
    struct Contacts: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "contacts",
                                                        abstract: "subcommand to get following")
        
        func run() throws {
            let keys = try Keys(privateKey: "aa3b75b54ca8e05db208b11e97b4bc6abd4e432abaf96c6f46c2cda955063d3e")
            let semaphore = DispatchSemaphore(value: 0)
            SporeSDK.initializeClient(with: keys)
            Task {
                let events = try await SporeSDK.getFollowingContacts()
                print("OUTPUT:\n\(events)")
//                semaphore.signal()
            }
            semaphore.wait()
        }
    }
}
