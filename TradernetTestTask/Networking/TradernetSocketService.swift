//
//  TradernetSocketService.swift
//  TradernetTestTask
//

import Foundation

final class TradernetSocketService: NSObject, WebSocketService {

    weak var delegate: WebSocketServiceDelegate?

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var pingInterval: TimeInterval = 25
    private var pingTimer: Timer?
    private var isConnected = false
    private var pendingTickers: [String]?

    func connect() {
        guard let url = URL(string: Constants.webSocketURL) else { return }
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        self.urlSession = session
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
    }

    func disconnect() {
        isConnected = false
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
    }

    func subscribe(to tickers: [String]) {
        if isConnected {
            sendSubscription(tickers)
        } else {
            pendingTickers = tickers
        }
    }

    // MARK: - Private

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
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

    private func handleMessage(_ text: String) {
        // Engine.IO open packet: "0{...}"
        if text.hasPrefix("0{") || text == "0" {
            handleOpenPacket(text)
            return
        }

        // Socket.IO connect ack: "40" or "40{...}"
        if text.hasPrefix("40") {
            handleConnectAck()
            return
        }

        // Engine.IO ping: "2"
        if text == "2" {
            sendRaw("3")
            return
        }

        // Socket.IO event: "42[...]"
        if text.hasPrefix("42") {
            handleEvent(text)
            return
        }
    }

    private func handleOpenPacket(_ text: String) {
        let jsonString = String(text.dropFirst(1))
        if let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let interval = json["pingInterval"] as? Double {
            pingInterval = interval / 1000.0
        }
        // Send Socket.IO connect to default namespace
        sendRaw("40")
    }

    private func handleConnectAck() {
        isConnected = true
        startPingTimer()
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.webSocketDidConnect()
            if let tickers = self?.pendingTickers {
                self?.pendingTickers = nil
                self?.sendSubscription(tickers)
            }
        }
    }

    private func handleEvent(_ text: String) {
        let payload = String(text.dropFirst(2))
        guard let parsed = SocketMessageParser.parse(payload) else { return }

        if parsed.event == "q", let quoteData = parsed.data as? [String: Any] {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.webSocketDidReceiveQuote(data: quoteData)
            }
        }
    }

    private func handleDisconnect(error: Error?) {
        isConnected = false
        pingTimer?.invalidate()
        pingTimer = nil
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.webSocketDidDisconnect(error: error)
        }
        // Auto-reconnect after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.connect()
        }
    }

    private func sendSubscription(_ tickers: [String]) {
        guard let data = try? JSONSerialization.data(
            withJSONObject: ["notifyQuotes", tickers],
            options: []
        ),
        let jsonString = String(data: data, encoding: .utf8) else { return }
        sendRaw("42\(jsonString)")
    }

    private func sendRaw(_ text: String) {
        webSocketTask?.send(.string(text)) { _ in }
    }

    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] _ in
            self?.sendRaw("2")
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension TradernetSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        // Connection opened at transport level; wait for Engine.IO open packet
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
