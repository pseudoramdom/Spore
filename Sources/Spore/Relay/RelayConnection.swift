import Foundation

/// Outlines a typical relay that is used by a Relay Pool
public protocol RelayConnectable {
    var url: URL { get }
    
    /// Describes if the relay socket connection is open
    var isOpen: Bool { get }
    
    /// Set a delegate to receive updates on connection events
    var delegate: RelayConnectionDelegate? { get set }
    
    /// Attempts to connect to the socket URL
    func connect()
    
    /// Disconnects from the socket URL
    func disconnect()
    
    /// Pings the socket connection to keep it alive
    func ping()
    
    /// Send message to relay
    func send(clientMessage: ClientMessageRepresentable)
}

/// Receive delegate calls on any updates from a particular relay connection
public protocol RelayConnectionDelegate: AnyObject {
    /// Indicates the relay connection was successful
    func relayConnectionDidConnect(_ connection: RelayConnection)
    
    /// Indicates the relay connection is dead despite attempts to reconnect
    func relayConnectionDidDisconnect(_ connection: RelayConnection)
    
    /// Received a message from the relay
    func relayConnection(_ connection: RelayConnection, didReceiveMessage relayMessage: Message.Relay)
    
    func relayConnection(_ connection: RelayConnection, didReceiveError error: Error)
}

public final class RelayConnection: NSObject, RelayConnectable {
    
    public let url: URL

    public private(set) var isOpen: Bool = false
    
    public weak var delegate: RelayConnectionDelegate?
    
    private let sessionConfiguration: URLSessionConfiguration!
    private var session: URLSession!
    private var socket: URLSessionWebSocketTask!
    
    private let maxReconnectCount = 5
    
    private let threadSafeCountQueue = DispatchQueue(label: "Spore.RelayConnection.count.queue", attributes: [.concurrent])
    
    private var reconnectAttempts: Int {
        get {
            return threadSafeCountQueue.sync {
                _underlyingReconnectAttemptsCount
            }
        }
        
        set {
            threadSafeCountQueue.async(flags: .barrier) { [unowned self] in
                self._underlyingReconnectAttemptsCount = newValue
            }
        }
    }
    
    private var _underlyingReconnectAttemptsCount = 0
    
    init(url: URL, sessionConfiguration: URLSessionConfiguration = .default) {
        self.url = url
        self.sessionConfiguration = sessionConfiguration
    }
    
    public func connect() {
        session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        socket = session.webSocketTask(with: url)
        listen()
        socket.resume()
    }
    
    public func disconnect() {
        socket.cancel(with: .goingAway, reason: nil)
    }
    
    public func send(clientMessage: ClientMessageRepresentable) {
        do {
            let encodedMessage = try clientMessage.encodedString()
            
            print("Constructed message:- \(encodedMessage)")
            
            socket.send(.string(encodedMessage)) { error in
                if let error = error {
                    print("ERROR: Websocket send error - \(String(describing: error))")
                    self.delegate?.relayConnection(self, didReceiveError: error)
                }
            }
        } catch {
            delegate?.relayConnection(self, didReceiveError: error)
        }
    }
    
    public func ping() {
        socket.sendPing { error in
            if let error = error {
                print("Failed to ping with error: \(error.localizedDescription)")
                self.delegate?.relayConnection(self, didReceiveError: error)
                self.reconnectIfPossible()
            }
        }
    }
}

extension RelayConnection {
    
    private func listen() {
        socket.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("ERROR: Received websocket error - \(String(describing: error))")
                self.delegate?.relayConnection(self, didReceiveError: error)
                self.reconnectIfPossible()
            case .success(let responseMessage):
                switch responseMessage {
                case .string(let text):
                    let relayMessageData = Data(text.utf8)
                    self.handle(messageData: relayMessageData)
                case .data(let messageData):
                    self.handle(messageData:messageData)
                @unknown default:
                    print("Unknown message type")
                }
            }
            self.listen()
        }
    }
    
    private func reconnectIfPossible() {
        guard self.reconnectAttempts < self.maxReconnectCount else {
            return
        }
        self.connect()
        self.reconnectAttempts += 1
    }
    private func handle(messageData: Data) {
        guard let relayMessage = try? JSONDecoder().decode(Message.Relay.self, from: messageData) else {
            print("ERROR: Relay Message Decode failed")
            return
        }
        print("RelayConnection.handleMessageData")
        delegate?.relayConnection(self, didReceiveMessage: relayMessage)
    }
}

extension RelayConnection: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isOpen = true
        delegate?.relayConnectionDidConnect(self)
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isOpen = false
        delegate?.relayConnectionDidDisconnect(self)
    }
}
