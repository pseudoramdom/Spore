import Foundation

public struct Metadata: Codable {
    let name: String?
    let displayName: String?
    let about: String?
    let picture: String?
    let website: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case about
        case picture
        case website = "nip05"
    }
    
    public init(name: String? = nil,
                displayName: String? = nil,
                about: String? = nil,
                picture: String? = nil,
                website: String? = nil) {
        self.name = name
        self.displayName = displayName
        self.about = about
        self.picture = picture
        self.website = website
    }
    
    public func encodedString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }
}
