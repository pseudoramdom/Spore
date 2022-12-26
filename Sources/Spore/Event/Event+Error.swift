import Foundation

extension Event {
    enum EventError: Error {
        case decodingFailed
        case encodingFailed
        case signingFailed
        case invalidEventId
        case invalidSignature
    }
}
