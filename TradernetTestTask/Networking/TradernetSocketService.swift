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

    private enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case disconnectedManually
    }

    private var state: ConnectionState = .disconnected
    private var retryCount = 0
    private let maxRetries = 10
    private let baseRetryInterval: TimeInterval = 1

    func connect() {
        guard state == .disconnected else { return }
        state = .connecting
        retryCount = 0
        openConnection()
    }

    func disconnect() {
        state = .disconnectedManually
        cancelReconnect()
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
        tearDownConnection()
    }

    // MARK: - Private

    private func openConnection() {
        tearDownConnection()

        guard let url = URL(string: Constants.webSocketURL) else {
            state = .disconnected
            return
        }
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        self.urlSession = session
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
    }

    private func tearDownConnection() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
    }

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    handleMessage(text)
                case .data:
                    break
                @unknown default:
                    break
                }
                listen()
            case .failure(let error):
                handleDisconnect(error: error)
            }
        }
    }

    private func handleMessage(_ text: String) {
        // Engine.IO ping/pong
        if text == "2" { sendRaw("3"); return }
        if text == "3" { return }

        // Socket.IO event: "42[...]"
        if text.hasPrefix("42") {
            handleEventPayload(String(text.dropFirst(2)))
            return
        }

        // Raw JSON array (server sends events without Engine.IO framing)
        if text.hasPrefix("[") {
            handleEventPayload(text)
            return
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

    private func handleDisconnect(error: Error?) {
        guard state != .disconnectedManually else { return }
        state = .disconnected
        delegate?.webSocketDidDisconnect(error: error)
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        guard retryCount < maxRetries else { return }
        let delay = baseRetryInterval * pow(2, Double(retryCount))
        let capped = min(delay, 30)
        retryCount += 1

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.state == .disconnected else { return }
            self.state = .connecting
            self.openConnection()
        }
        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + capped, execute: workItem)
    }

    private func cancelReconnect() {
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
    }

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
        // Wait for server's userData event before subscribing
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        handleDisconnect(error: nil)
    }
}

// MARK: - Socket Message Parser

enum SocketMessageParser {

    struct ParsedMessage {
        let event: String
        let data: Any?
    }

    static func parse(_ payload: String) -> ParsedMessage? {
        guard let data = payload.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let event = array.first as? String else {
            return nil
        }
        let eventData = array.count > 1 ? array[1] : nil
        return ParsedMessage(event: event, data: eventData)
    }
}
