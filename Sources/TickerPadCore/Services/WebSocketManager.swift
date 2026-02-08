import Foundation

public struct WebSocketTick: Equatable, Sendable {
    public let symbol: String
    public let currentPrice: Double

    public init(symbol: String, currentPrice: Double) {
        self.symbol = symbol
        self.currentPrice = currentPrice
    }
}

public protocol WebSocketManaging: Sendable {
    func connect(symbols: [String]) async
    func disconnect() async
    var ticks: AsyncStream<WebSocketTick> { get }
}

public actor StubWebSocketManager: WebSocketManaging {
    private let stream: AsyncStream<WebSocketTick>
    private let continuation: AsyncStream<WebSocketTick>.Continuation

    public nonisolated var ticks: AsyncStream<WebSocketTick> {
        stream
    }

    public init() {
        var localContinuation: AsyncStream<WebSocketTick>.Continuation?
        self.stream = AsyncStream<WebSocketTick> { continuation in
            localContinuation = continuation
        }
        self.continuation = localContinuation!
    }

    public func connect(symbols: [String]) async {
        _ = symbols
    }

    public func disconnect() async {
        continuation.finish()
    }

    public func emit(_ tick: WebSocketTick) {
        continuation.yield(tick)
    }
}
