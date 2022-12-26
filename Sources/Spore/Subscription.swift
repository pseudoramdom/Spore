import Foundation

public typealias SubscriptionId = String

public struct Subscription: Encodable {
    public let id: SubscriptionId
    public let filters: [Filter]
    
    public init(id: String, filters: [Filter]) {
        self.id = id
        self.filters = filters
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(id)
        try filters.forEach { filter in
            try container.encode(filter)
        }
    }
}
