import Foundation

/// Filter determines what events will be sent in that subscription
///
/// Ref: [NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md)
public struct Filter: Encodable {
    
    /// a list of event ids or prefixes
    public let ids: [String]?
    
    /// a list of pubkeys or prefixes, the pubkey of an event must be one of these
    public let authors: [String]?
    public let kinds: [Int]?
    public let eventTags: [String]?
    public let publicKeyTags: [String]?
    
    /// Used for hashtags in Posts
    ///
    /// clients can use simple t ("hashtag") tags to associate an event with an easily searchable topic name. Since Nostr events themselves are not searchable through the protocol, this provides a mechanism for user-driven search.
    /// Ref: [NIP-12](https://github.com/nostr-protocol/nips/blob/master/12.md#suggested-use-cases)
    public let hashtags: [String]?
    
    /// Used for Location-specific Posts
    ///
    /// clients can use a g ("geohash") tag to associate a post with a physical location. Clients can search for a set of geohashes of varying precisions near them to find local content.
    /// Ref: [NIP-12](https://github.com/nostr-protocol/nips/blob/master/12.md#suggested-use-cases)
    public let geoTags: [String]?
    public let referenceTags: [String]?
    public let since: TimeInterval?
    public let until: TimeInterval?
    public let limit: Int?
    
    private enum CodingKeys: String, CodingKey {
        case ids
        case authors
        case kinds
        case eventTags = "#e"
        case publicKeyTags = "#p"
        case hashtags = "#t"
        case geoTags = "#g"
        case referenceTags = "#r"
        case since
        case until
        case limit
    }
    
    public init(
        ids: [String]? = nil,
        authors: [String]? = nil,
        kinds: [Int]? = nil,
        eventTags: [String]? = nil,
        publicKeyTags: [String]? = nil,
        hashtags: [String]? = nil,
        geoTags: [String]? = nil,
        referenceTags: [String]? = nil,
        since: TimeInterval? = nil,
        until: TimeInterval? =  nil,
        limit: Int? = nil) {
            self.ids = ids
            self.authors = authors
            self.kinds = kinds
            self.eventTags = eventTags
            self.publicKeyTags = publicKeyTags
            self.hashtags = hashtags
            self.geoTags = geoTags
            self.referenceTags = referenceTags
            self.since = since
            self.until = until
            self.limit = limit
        }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(ids, forKey: .ids)
        try container.encodeIfPresent(authors, forKey: .authors)
        try container.encodeIfPresent(kinds, forKey: .kinds)
        try container.encodeIfPresent(eventTags, forKey: .eventTags)
        try container.encodeIfPresent(publicKeyTags, forKey: .publicKeyTags)
        try container.encodeIfPresent(hashtags, forKey: .hashtags)
        try container.encodeIfPresent(geoTags, forKey: .geoTags)
        try container.encodeIfPresent(since, forKey: .since)
        try container.encodeIfPresent(until, forKey: .until)
        try container.encodeIfPresent(limit, forKey: .limit)
    }
}
