import Foundation

public enum SporeResponse {
    case message(relay: URL, message: Message.Relay)
    case relayStatus(relay: URL, status: RelayConnection.Status)
    case relayError(error: Error)
}
