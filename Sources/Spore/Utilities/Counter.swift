import Foundation

public actor Counter {
    
    enum CounterError: Error {
        case limitReached
    }
    
    public var count: Int
    public let limit: Int
    private let startingValue: Int
    
    init(_ startingValue: Int = 0, limit: Int = .max) {
        self.count = startingValue
        self.startingValue = startingValue
        self.limit = limit
    }
    
    func increment() throws -> Int {
        guard count < limit else {
            throw CounterError.limitReached
        }
        count += 1
        return count
    }
    
    func reset() {
        count = startingValue
    }
}
