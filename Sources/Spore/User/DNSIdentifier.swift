import Foundation

public typealias DNSIdentifier = String

public struct DNSIdentifiedUser: Decodable {
    public let publicKey: String
    public let relays: [String]
}

public struct DNSIdentifierResult: Decodable {
    public let names: [String: PublicKeyHex]
    public let relays: [PublicKeyHex: [String]]?
}

public class DNSIdentifierValidator {
    
    public let dnsIdentifier: DNSIdentifier
    private let session: URLSession
    
    public init(dnsIdentifier: DNSIdentifier, urlSession: URLSession = .shared) {
        self.dnsIdentifier = dnsIdentifier
        self.session = urlSession
    }
    
    public func validate() async throws -> DNSIdentifiedUser {
        let components = dnsIdentifier.components(separatedBy: "@")
        
        guard components.count == 2 else {
            throw DNSIdentifierValidationError.invalidDNSIdentifier
        }
        
        let userHandle = components[0]
        let domain = components[1]
        
        guard let url = URL(string: "https://\(domain)/.well-known/nostr.json?name=\(userHandle)") else {
            throw DNSIdentifierValidationError.invalidDNSIdentifier
        }
        
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let result = try? JSONDecoder().decode(DNSIdentifierResult.self, from: data) else {
            throw DNSIdentifierValidationError.validationError
        }
        
        guard let publicKey = result.names[userHandle] else {
            throw DNSIdentifierValidationError.validationError
        }
        
        let relays: [String]
        if let userRelays = result.relays?[publicKey] {
            relays = userRelays
        } else {
            relays = []
        }
        
        return DNSIdentifiedUser(publicKey: publicKey,
                                 relays: relays)
    }
}

public enum DNSIdentifierValidationError: Error, LocalizedError {
    case invalidDNSIdentifier
    case validationError
    
    public var errorDescription: String? {
        switch self {
        case .invalidDNSIdentifier:
            return "Invalid DNS identifier"
        case .validationError:
            return "Failed to validate DNS identifier"
        }
    }
}
