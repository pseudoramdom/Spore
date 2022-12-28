import Foundation

/// Outlines a typical relay that is used by a Relay Pool
public protocol RelayConnectable {
    var url: URL { get }
    
    /// Attempts to reconnect to the socket URL
    func reconnect() async throws
    
    /// Disconnects from the socket URL
    func disconnect()
    
    /// Pings the socket connection to keep it alive
    func ping()
    
    /// Send message to relay
    func send(clientMessage: ClientMessageRepresentable) async throws
}

enum RelayConnectionError: Error {
    case failedToDecodeMessage
}

public final class RelayConnection: AsyncSequence, RelayConnectable {
    
    public typealias Element = Message.Relay
    public typealias AsyncIterator = AsyncThrowingStream<Message.Relay, Error>.Iterator
    
    public let url: URL
    public private(set) var isOpen: Bool = false
    
    private var session: URLSession
    private var socket: URLSessionWebSocketTask
    
    private lazy var jsonDecoder = JSONDecoder()
    
    private var messageStream: AsyncThrowingStream<Element, Error>?
    private var continuation: AsyncThrowingStream<Element, Error>.Continuation?
    
    private var pingTimer: Timer?
    
    private let reconnectAttemptCounter = Counter(limit: 5)
    
    init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
        
        socket = session.webSocketTask(with: url)
        messageStream = AsyncThrowingStream { continuation in
            self.continuation = continuation
            self.continuation?.onTermination = { @Sendable [socket] _ in
                socket.cancel(with: .goingAway, reason: nil)
                self.pingTimer?.invalidate()
            }
        }
    }
    
    public func makeAsyncIterator() -> AsyncThrowingStream<Message.Relay, Error>.Iterator {
        guard let stream = messageStream else {
            fatalError("Stream was not initialized")
        }
        socket.resume()
        listenForMessages()
        return stream.makeAsyncIterator()
    }
    
    public func reconnect() async throws {
        _ = try await reconnectAttemptCounter.increment()
        socket = session.webSocketTask(with: url)
    }
    
    public func disconnect() {
        socket.cancel(with: .goingAway, reason: nil)
        pingTimer?.invalidate()
    }
    
    public func send(clientMessage: ClientMessageRepresentable) async throws {
        let encodedMessage = try clientMessage.encodedString()
        print("Constructed message:- \(encodedMessage)")
        try await socket.send(.string(encodedMessage))
    }
    
    public func ping() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
            self.pingSocket()
        }
    }
}

extension RelayConnection {
    
    private func listenForMessages() {
        socket.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("ERROR: Received websocket error - \(String(describing: error))")
                self.continuation?.finish(throwing: error)
            case .success(let responseMessage):
                switch responseMessage {
                case .string(let text):
                    let relayMessageData = Data(text.utf8)
                    self.handle(messageData: relayMessageData)
                case .data(let messageData):
                    self.handle(messageData: messageData)
                @unknown default:
                    print("Unknown message type")
                    self.continuation?.finish(throwing: RelayConnectionError.failedToDecodeMessage)
                }
            }
        }
    }
    
    private func handle(messageData: Data) {
        guard let relayMessage = try? JSONDecoder().decode(Message.Relay.self, from: messageData) else {
            if let stringMessage = String(data: messageData, encoding: .utf8) {
                print("ERROR: Failed to decode to known message type.")
                print("\(stringMessage)")
            } else {
                print("ERROR: Relay Message Decode failed")
            }
            continuation?.finish(throwing: RelayConnectionError.failedToDecodeMessage)
            return
        }
        print("RelayConnection.handleMessageData")
        continuation?.yield(relayMessage)
    }
    
    private func pingSocket() {
        socket.sendPing { error in
            if let error = error {
                print("Failed to ping with error: \(String(describing: error))")
            }
        }
    }
}
