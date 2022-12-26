import Foundation

public enum RelayPoolError: Error {
    case relayAlreadyExists
    case relayDoesNotExist
    case deallocated
    case noRelaysAdded
    case relayError(message: String)
}
