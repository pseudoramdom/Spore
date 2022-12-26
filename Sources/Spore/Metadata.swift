import Foundation

public struct Metadata {
    let name: String?
    let displayName: String?
    let about: String?
    let picture: String?
    let nip05: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case about
        case picture
        case nip05
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
}
