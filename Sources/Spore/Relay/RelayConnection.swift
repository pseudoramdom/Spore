import Foundation

/// Outlines a typical relay that is used by a Relay Pool
public protocol RelayConnectable {
    var url: URL { get }
    
    /// Describes the status of relay socket connection
    var status: RelayConnection.Status { get }
    
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
    func relayConnection(_ connection: RelayConnection, didChange status: RelayConnection.Status)
    
    /// Received a message from the relay
    func relayConnection(_ connection: RelayConnection, didReceiveMessage relayMessage: Message.Relay)
    
    func relayConnection(_ connection: RelayConnection, didReceiveError error: Error)
}

public final class RelayConnection: NSObject, RelayConnectable {
    
    public let url: URL

    public var status: RelayConnection.Status = .unOpened {
        didSet {
            delegate?.relayConnection(self, didChange: status)
        }
    }
    
    public weak var delegate: RelayConnectionDelegate?
    
    private let sessionConfiguration: URLSessionConfiguration!
    private var session: URLSession!
    private var socket: URLSessionWebSocketTask!
    
    private var pingTimer: Timer?
    
    init(url: URL, sessionConfiguration: URLSessionConfiguration = .default) {
        self.url = url
        self.sessionConfiguration = sessionConfiguration
    }
    
    public func connect() {
        session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        socket = session.webSocketTask(with: url)
        listen()
        socket.resume()
        status = .connecting
    }
    
    public func disconnect() {
        socket.cancel(with: .goingAway, reason: nil)
        pingTimer?.invalidate()
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
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
            self.pingSocket()
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
    
    private func handle(messageData: Data) {
        guard let relayMessage = try? JSONDecoder().decode(Message.Relay.self, from: messageData) else {
            if let stringMessage = String(data: messageData, encoding: .utf8) {
                print("ERROR: Failed to decode to known message type.")
                print("\(stringMessage)")
            } else {
                print("ERROR: Relay Message Decode failed")
            }
            print("ERROR: Relay Message Decode failed")
            return
        }
        print("RelayConnection.handleMessageData")
        delegate?.relayConnection(self, didReceiveMessage: relayMessage)
    }
    
    private func pingSocket() {
        socket.sendPing { error in
            if let error = error {
                print("Failed to ping with error: \(String(describing: error))")
                if self.status != .notReachable {
                    self.status = .notReachable
                }
            }
        }
    }
}

extension RelayConnection: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        status = .connected
        ping()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        status = .disconnected
        pingTimer?.invalidate()
    }
}

extension RelayConnection {
    public enum Status {
        case unOpened
        case connecting
        case connected
        case notReachable
        case disconnected
    }
}
