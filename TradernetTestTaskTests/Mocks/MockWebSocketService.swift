//
//  MockWebSocketService.swift
//  TradernetTestTaskTests
//

import Foundation
@testable import TradernetTestTask

final class MockWebSocketService: WebSocketService {

    weak var delegate: WebSocketServiceDelegate?

    private(set) var connectCallCount = 0
    private(set) var disconnectCallCount = 0
    private(set) var subscribedTickers: [String] = []

    func connect() {
        connectCallCount += 1
    }

    func disconnect() {
        disconnectCallCount += 1
    }

    func subscribe(to tickers: [String]) {
        subscribedTickers = tickers
    }

    func resetSubscribedTickers() {
        subscribedTickers = []
    }

    // MARK: - Simulation

    func simulateConnect() {
        delegate?.webSocketDidConnect()
    }

    func simulateQuote(data: [String: Any]) {
        delegate?.webSocketDidReceiveQuote(data: data)
    }

    func simulateDisconnect(error: Error? = nil) {
        delegate?.webSocketDidDisconnect(error: error)
    }
}
