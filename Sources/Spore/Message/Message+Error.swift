import Foundation

public extension Message {
    enum MessageError: Error {
        case decodingFailed
        case encodingError
    }
}
