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

public enum WebSocketMessageParser {
    public static func parseTick(from data: Data) -> WebSocketTick? {
        if let combined = try? JSONDecoder().decode(CombinedStreamPayload.self, from: data),
           let tick = combined.data {
            return WebSocketTick(symbol: tick.symbol.uppercased(), currentPrice: Double(tick.currentPrice) ?? 0)
        }

        if let direct = try? JSONDecoder().decode(MiniTickerPayload.self, from: data) {
            return WebSocketTick(symbol: direct.symbol.uppercased(), currentPrice: Double(direct.currentPrice) ?? 0)
        }

        return nil
    }

    private struct CombinedStreamPayload: Decodable {
        let data: MiniTickerPayload?
    }

    private struct MiniTickerPayload: Decodable {
        let symbol: String
        let currentPrice: String

        enum CodingKeys: String, CodingKey {
            case symbol = "s"
            case currentPrice = "c"
        }
    }
}

public actor BinanceWebSocketManager: WebSocketManaging {
    private final class ResumeGate: @unchecked Sendable {
        private let lock = NSLock()
        private var resumed = false

        func claim() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            guard !resumed else { return false }
            resumed = true
            return true
        }
    }

    private let session: URLSession
    private let baseURL: String
    private let backoff: ExponentialBackoff

    private var subscribedSymbols: [String] = []
    private var socketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var shouldRun = false
    private var reconnectAttempt = 0

    private let stream: AsyncStream<WebSocketTick>
    private let continuation: AsyncStream<WebSocketTick>.Continuation

    public nonisolated var ticks: AsyncStream<WebSocketTick> {
        stream
    }

    public init(
        session: URLSession = .shared,
        baseURL: String = "wss://stream.binance.com:9443",
        backoff: ExponentialBackoff = ExponentialBackoff()
    ) {
        self.session = session
        self.baseURL = baseURL
        self.backoff = backoff

        var localContinuation: AsyncStream<WebSocketTick>.Continuation?
        self.stream = AsyncStream<WebSocketTick> { continuation in
            localContinuation = continuation
        }
        self.continuation = localContinuation!
    }

    public func connect(symbols: [String]) async {
        let normalized = Array(Set(symbols.map { $0.lowercased() })).sorted()
        subscribedSymbols = normalized
        shouldRun = !normalized.isEmpty

        if !shouldRun {
            await disconnect()
            return
        }

        await establishConnection()
    }

    public func disconnect() async {
        shouldRun = false
        reconnectAttempt = 0

        reconnectTask?.cancel()
        reconnectTask = nil

        pingTask?.cancel()
        pingTask = nil

        receiveTask?.cancel()
        receiveTask = nil

        socketTask?.cancel(with: .goingAway, reason: nil)
        socketTask = nil
    }

    private func establishConnection() async {
        await stopCurrentSocket()

        guard let requestURL = makeRequestURL(symbols: subscribedSymbols) else {
            return
        }

        let task = session.webSocketTask(with: requestURL)
        socketTask = task
        task.resume()

        startPingLoop(using: task)
        startReceiveLoop(using: task)
    }

    private func stopCurrentSocket() async {
        pingTask?.cancel()
        pingTask = nil

        receiveTask?.cancel()
        receiveTask = nil

        socketTask?.cancel(with: .goingAway, reason: nil)
        socketTask = nil
    }

    private func makeRequestURL(symbols: [String]) -> URL? {
        guard !symbols.isEmpty else { return nil }
        let streams = symbols.map { "\($0)@miniTicker" }.joined(separator: "/")
        return URL(string: "\(baseURL)/stream?streams=\(streams)")
    }

    private func startPingLoop(using task: URLSessionWebSocketTask) {
        pingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { return }
                do {
                    try await sendPing(task: task)
                } catch {
                    await handleDisconnect()
                    return
                }
            }
        }
    }

    private func sendPing(task: URLSessionWebSocketTask) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let gate = ResumeGate()

            task.sendPing { error in
                guard gate.claim() else { return }

                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func startReceiveLoop(using task: URLSessionWebSocketTask) {
        receiveTask = Task {
            while !Task.isCancelled {
                do {
                    let message = try await task.receive()
                    reconnectAttempt = 0

                    switch message {
                    case .string(let text):
                        if let data = text.data(using: .utf8),
                           let tick = WebSocketMessageParser.parseTick(from: data) {
                            continuation.yield(tick)
                        }
                    case .data(let data):
                        if let tick = WebSocketMessageParser.parseTick(from: data) {
                            continuation.yield(tick)
                        }
                    @unknown default:
                        break
                    }
                } catch {
                    await handleDisconnect()
                    return
                }
            }
        }
    }

    private func handleDisconnect() async {
        guard shouldRun else { return }

        await stopCurrentSocket()
        reconnectAttempt += 1

        reconnectTask?.cancel()
        reconnectTask = Task {
            let delay = backoff.delay(for: reconnectAttempt)
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await establishConnection()
        }
    }
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

    public func disconnect() async {}

    public func emit(_ tick: WebSocketTick) {
        continuation.yield(tick)
    }
}
