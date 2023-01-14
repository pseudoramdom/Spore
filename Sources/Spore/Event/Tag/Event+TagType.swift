import Foundation

extension Event.Tag {
    public struct TagType: RawRepresentable, Codable, Equatable {
        public typealias RawValue = String
        
        public static let event = TagType(rawValue: "e")!
        public static let publicKey = TagType(rawValue: "p")!
        
        /// Used in interpreting Proof-of-work
        ///
        /// Ref - [NIP-13](https://github.com/nostr-protocol/nips/blob/master/13.md)
        public static let nonce = TagType(rawValue: "nonce")!
        
        /// For event delegation
        ///
        /// Ref - [NIP-26](https://github.com/nostr-protocol/nips/blob/master/26.md)
        public static let delegation = TagType(rawValue: "delegation")!
        
        public var rawValue: String
        
        public init?(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }
}
