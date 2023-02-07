import ArgumentParser

struct SporeCLI: ParsableCommand {
    static var configuration = CommandConfiguration(commandName:"spore-cli",
                                                    abstract: "CLI tool to test NostrSwift implementation",
                                                    subcommands: [Event.self,
                                                                  Subscribe.self,
                                                                  KeyGen.self
//                                                                  Profile.self
                                                                 ])
}

SporeCLI.main()
