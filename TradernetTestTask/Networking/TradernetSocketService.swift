//
//  TradernetSocketService.swift
//  TradernetTestTask
//

import Foundation

final class TradernetSocketService: NSObject, WebSocketService {

    weak var delegate: WebSocketServiceDelegate?

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
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
            if !isConnected {
                isConnected = true
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
        isConnected = false
        delegate?.webSocketDidDisconnect(error: error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.connect()
        }
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
