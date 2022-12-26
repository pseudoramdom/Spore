import Foundation

extension Event {
    
    public struct Kind: RawRepresentable, Codable, Equatable {
        public typealias RawValue = Int
        
        public static let setMetadata = Kind(rawValue: 0)
        public static let textNote = Kind(rawValue: 1)
        public static let recommendRelayServer = Kind(rawValue: 2)
        public static let contactList = Kind(rawValue: 3)
        public static let encryptedDirectMessage = Kind(rawValue: 4)
        public static let eventDeletion = Kind(rawValue: 5)
        public static let reaction = Kind(rawValue: 7)
        public static let channelCreation = Kind(rawValue: 40)
        public static let channelMetadata = Kind(rawValue: 41)
        public static let channelMessage = Kind(rawValue: 42)
        public static let channelHideMessage = Kind(rawValue: 43)
        public static let channelMuteUser = Kind(rawValue: 44)
        
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }
}
