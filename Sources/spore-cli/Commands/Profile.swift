import Foundation
import ArgumentParser
import Spore

extension SporeCLI {
    struct Profile: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "profile",
                                                        abstract: "subcommand related to profile",
                                                        subcommands: [Following.self,
                                                                      UpdateProfile.self,
                                                                      GetProfile.self])
    }
}

extension SporeCLI.Profile {
    struct Following: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "get-following",
                                                        abstract: "subcommand to fetch following authors")
        
        
        @Argument
        var publicKey: String
        
        func run() throws {
            let keys = try Keys(privateKey: "aa3b75b54ca8e05db208b11e97b4bc6abd4e432abaf96c6f46c2cda955063d3e")
            let semaphore = DispatchSemaphore(value: 0)
            SporeSDK.initializeClient(with: keys)
            
            sleep(2)
            print("sending...")
            
            SporeSDK.client.eventReceiveHandler = { (subscriptionId, event) in
                print("RECEIVED - \(subscriptionId)\n\(event)")
            }
            SporeSDK.getFollowingContacts(publicKey: publicKey)
            semaphore.wait()
        }
    }
    
    struct UpdateProfile: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "update-profile",
                                                        abstract: "subcommand to fetch following authors")
        
        
        func run() throws {
            let keys = try Keys(privateKey: "aa3b75b54ca8e05db208b11e97b4bc6abd4e432abaf96c6f46c2cda955063d3e")
            let semaphore = DispatchSemaphore(value: 0)
            SporeSDK.initializeClient(with: keys)
            
            sleep(2)
            print("sending...")
            
            let metadata = Metadata(about: "wassa wasaaa")
            try? SporeSDK.update(metadata: metadata)
            semaphore.wait()
        }
    }
    
    struct GetProfile: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "get-profile",
                                                        abstract: "subcommand to fetch following authors")
        
        @Argument
        var publicKey: String
        
        func run() throws {
            let keys = try Keys(privateKey: "aa3b75b54ca8e05db208b11e97b4bc6abd4e432abaf96c6f46c2cda955063d3e")
            let semaphore = DispatchSemaphore(value: 0)
            SporeSDK.initializeClient(with: keys)
            
            sleep(2)
            print("sending...")
            
            SporeSDK.client.eventReceiveHandler = { (subscriptionId, event) in
                print("RECEIVED - \(subscriptionId)\n\(event)")
            }
            try? SporeSDK.getProfile(publicKey: publicKey)
            semaphore.wait()
        }
    }
}

/*
 11cc106e72c654b64bb037d0ccbe2ff47187fa5bb77330dd70398c2cb051fbd6
 c2441dc0e1dee6d00beb480c707ba0e559a5089648fcf602d01af5959ca92ecc // pseudo
 */
