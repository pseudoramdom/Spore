import Foundation

public struct Metadata: Codable {
    public let name: String?
    public let displayName: String?
    public let about: String?
    public let picture: String?
    
    /// NIP-05 identifier
    public let dnsIdentifier: DNSIdentifier?
    
    public var lastUpdatedAt: Int64?
    public var publicKey: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case about
        case picture
        case dnsIdentifier = "nip05"
    }
    
    public init(name: String? = nil,
                displayName: String? = nil,
                about: String? = nil,
                picture: String? = nil,
                dnsIdentifier: DNSIdentifier? = nil) {
        self.name = name
        self.displayName = displayName
        self.about = about
        self.picture = picture
        self.dnsIdentifier = dnsIdentifier
    }
    
    public func encodedString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }
    
    
}
