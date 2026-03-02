//
//  TradernetSocketService.swift
//  TradernetTestTask
//

import Foundation

final class TradernetSocketService: NSObject, WebSocketService {

    weak var delegate: WebSocketServiceDelegate?

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var pendingTickers: [String]?
    private var reconnectWorkItem: DispatchWorkItem?
    private var connectionTimeoutWorkItem: DispatchWorkItem?
    private var activityTimeoutWorkItem: DispatchWorkItem?

    private enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case disconnectedManually
    }

    private var state: ConnectionState = .disconnected
    private var retryCount = 0
    private let reconnectStrategy: ReconnectStrategy
    private let connectionTimeout: TimeInterval
    private let activityTimeout: TimeInterval

    // MARK: - Weak Delegate Proxy

    /// Prevents URLSession from strongly retaining `TradernetSocketService`.
    /// URLSession keeps a strong reference to its delegate; this proxy breaks that cycle
    /// by holding only a weak reference back to the service.
    private class WeakSessionDelegate: NSObject, URLSessionWebSocketDelegate {
        weak var target: TradernetSocketService?

        init(target: TradernetSocketService) {
            self.target = target
        }

        func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                        didOpenWithProtocol protocol: String?) {
            target?.urlSession(session, webSocketTask: webSocketTask, didOpenWithProtocol: `protocol`)
        }

        func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            target?.urlSession(session, webSocketTask: webSocketTask, didCloseWith: closeCode, reason: reason)
        }
    }

    private var sessionDelegate: WeakSessionDelegate?

    // MARK: - Init

    init(reconnectStrategy: ReconnectStrategy = ReconnectStrategy(),
         connectionTimeout: TimeInterval = 15,
         activityTimeout: TimeInterval = 45) {
        self.reconnectStrategy = reconnectStrategy
        self.connectionTimeout = connectionTimeout
        self.activityTimeout = activityTimeout
        super.init()
    }

    // MARK: - WebSocketService

    func connect() {
        guard state == .disconnected || state == .disconnectedManually else { return }
        state = .connecting
        retryCount = 0
        openConnection()
    }

    func disconnect() {
        state = .disconnectedManually
        cancelReconnect()
        cancelTimeouts()
        tearDownConnection()
        delegate?.webSocketDidDisconnect(error: nil)
    }

    func subscribe(to tickers: [String]) {
        if state == .connected {
            sendSubscription(tickers)
        } else {
            pendingTickers = tickers
        }
    }

    deinit {
        cancelReconnect()
        cancelTimeouts()
        tearDownConnection()
    }

    // MARK: - Connection Lifecycle

    private func openConnection() {
        tearDownConnection()

        guard let url = URL(string: Constants.webSocketURL) else {
            state = .disconnected
            return
        }

        let proxy = WeakSessionDelegate(target: self)
        sessionDelegate = proxy
        let session = URLSession(configuration: .default, delegate: proxy, delegateQueue: .main)
        self.urlSession = session
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
        scheduleConnectionTimeout()
    }

    private func tearDownConnection() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        sessionDelegate = nil
    }

    // MARK: - Listening

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                self.resetActivityTimeout()
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data:
                    break
                @unknown default:
                    break
                }
                self.listen()
            case .failure(let error):
                self.handleDisconnect(error: error)
            }
        }
    }

    // MARK: - Message Handling

    private func handleMessage(_ text: String) {
        switch SocketMessageParser.detectFrame(text) {
        case .ping:
            sendRaw(SocketMessageParser.pongFrame)
        case .pong:
            break
        case .socketIOEvent(let payload), .rawJSONEvent(let payload):
            handleEventPayload(payload)
        case .unknown:
            break
        }
    }

    private func handleEventPayload(_ payload: String) {
        guard let parsed = SocketMessageParser.parse(payload) else { return }

        switch parsed.event {
        case "q":
            if let quoteData = parsed.data as? [String: Any] {
                delegate?.webSocketDidReceiveQuote(data: quoteData)
            }
        case "userData":
            if state != .connected {
                state = .connected
                retryCount = 0
                cancelConnectionTimeout()
                delegate?.webSocketDidConnect()
                if let tickers = pendingTickers {
                    pendingTickers = nil
                    sendSubscription(tickers)
                }
            }
        default:
            break
        }
    }

    // MARK: - Disconnect & Reconnect

    private func handleDisconnect(error: Error?) {
        guard state != .disconnectedManually else { return }
        cancelTimeouts()
        state = .disconnected
        delegate?.webSocketDidDisconnect(error: error)
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        guard reconnectStrategy.canRetry(attempt: retryCount) else {
            delegate?.webSocketDidExhaustRetries()
            return
        }
        let delay = reconnectStrategy.delay(forAttempt: retryCount)
        retryCount += 1

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.state == .disconnected else { return }
            self.state = .connecting
            self.openConnection()
        }
        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func cancelReconnect() {
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
    }

    // MARK: - Timeouts

    private func scheduleConnectionTimeout() {
        cancelConnectionTimeout()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.state == .connecting else { return }
            self.handleDisconnect(error: nil)
        }
        connectionTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + connectionTimeout, execute: workItem)
    }

    private func cancelConnectionTimeout() {
        connectionTimeoutWorkItem?.cancel()
        connectionTimeoutWorkItem = nil
    }

    private func resetActivityTimeout() {
        cancelActivityTimeout()
        guard state == .connected || state == .connecting else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.state == .connected else { return }
            self.handleDisconnect(error: nil)
        }
        activityTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + activityTimeout, execute: workItem)
    }

    private func cancelActivityTimeout() {
        activityTimeoutWorkItem?.cancel()
        activityTimeoutWorkItem = nil
    }

    private func cancelTimeouts() {
        cancelConnectionTimeout()
        cancelActivityTimeout()
    }

    // MARK: - Sending

    private func sendSubscription(_ tickers: [String]) {
        guard let data = try? JSONSerialization.data(
            withJSONObject: ["quotes", tickers], options: []
        ), let jsonString = String(data: data, encoding: .utf8) else { return }
        sendRaw(jsonString)
    }

    private func sendRaw(_ text: String) {
        webSocketTask?.send(.string(text)) { error in
            if let error = error {
                print("[WS] Send error: \(error)")
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension TradernetSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        // Wait for server's userData event before declaring connected
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        handleDisconnect(error: nil)
    }
}
