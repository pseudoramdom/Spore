import Foundation

public struct Metadata: Codable {
    public let name: String?
    public let displayName: String?
    public let about: String?
    public let picture: String?
    public let nip05: String?
    
    public var lastUpdatedAt: Int64?
    public var publicKey: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case about
        case picture
        case nip05 = "nip05"
    }
    
    public init(name: String? = nil,
                displayName: String? = nil,
                about: String? = nil,
                picture: String? = nil,
                nip05: String? = nil) {
        self.name = name
        self.displayName = displayName
        self.about = about
        self.picture = picture
        self.nip05 = nip05
    }
    
    public func encodedString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }
    
    
}
