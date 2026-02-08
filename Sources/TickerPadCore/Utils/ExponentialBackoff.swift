import Foundation

public struct ExponentialBackoff: Sendable {
    public let maxDelay: TimeInterval
    public let baseDelay: TimeInterval

    public init(baseDelay: TimeInterval = 1, maxDelay: TimeInterval = 60) {
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }

    public func delay(for attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return baseDelay }
        let value = baseDelay * pow(2, Double(attempt - 1))
        return min(maxDelay, value)
    }
}
