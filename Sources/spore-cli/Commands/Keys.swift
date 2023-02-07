import Foundation
import ArgumentParser
import Spore

extension SporeCLI {
    struct KeyGen: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "keygen", abstract: "subcommand to generate keys")
        
        @Argument(help: "PubKey prefix")
        var prefix: String
        
        func run() throws {
//            while true {
//                let keys = try Keys()
//                let bech32String = try Bech32Coder().encode(humanReadablePart: Bech32Coder.HumanReadablePart.publicKey, keys.publicKey)
//
//                let dataPart = bech32String.suffix(bech32String.count - Bech32Coder.HumanReadablePart.publicKey.count - 1)
//
//                if dataPart.hasPrefix(prefix) {
//                    print("Private Key - \(keys.privateKey.rawRepresentation.hexEncodedString)")
//                    print("Public Key - \(keys.publicKey)")
//                    print("bech32 pubkey - \(bech32String)")
//                    break
//                } else {
//                    print("discarding - \(bech32String)")
//                }
//            }
            
            let group = DispatchGroup()
            let queue = DispatchQueue(label: "", attributes: .concurrent)

            var shouldStop = false
            while !shouldStop {
                queue.async(group: group, execute: {
                    let keys = try! Keys()
                    let bech32PrivateKey = try! Bech32Coder().encode(humanReadablePart: Bech32Coder.HumanReadablePart.publicKey, keys.privateKey.rawRepresentation.hexEncodedString)
                    let bech32PublicKey = try! Bech32Coder().encode(humanReadablePart: Bech32Coder.HumanReadablePart.publicKey, keys.publicKey)
                    
                    let dataPart = bech32PublicKey.suffix(bech32PublicKey.count - Bech32Coder.HumanReadablePart.publicKey.count - 1)
                    
                    if dataPart.hasPrefix(prefix) {
                        print("Bech32 Public Key - \(bech32PrivateKey)")
                        print("Bech32 Public Key - \(bech32PublicKey)")
                        shouldStop = true
                    } else {
//                        print("discarding - \(bech32String)")
                    }
                })
            }

            _ = group.wait(timeout: .distantFuture)
        }
    }
}
