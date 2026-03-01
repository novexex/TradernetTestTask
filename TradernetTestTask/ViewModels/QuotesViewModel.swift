//
//  QuotesViewModel.swift
//  TradernetTestTask
//

import Foundation

protocol QuotesViewModelDelegate: AnyObject {
    func quotesDidUpdate(at indexes: [Int])
    func quotesDidReload()
}

final class QuotesViewModel: WebSocketServiceDelegate {

    weak var delegate: QuotesViewModelDelegate?

    private(set) var quotes: [Quote] = []
    private var tickerIndexMap: [String: Int] = [:]
    private let service: WebSocketService
    private let tickers: [String]

    /// Tracks the previous percent change per ticker to detect direction flips
    private var previousPercentChange: [String: Double] = [:]

    /// Stores the latest change direction per ticker for cell animation
    private(set) var changeDirections: [String: Quote.ChangeDirection] = [:]

    init(service: WebSocketService, tickers: [String] = Constants.tickers) {
        self.service = service
        self.tickers = tickers
        self.service.delegate = self
        initializeQuotes()
    }

    func start() {
        service.connect()
    }

    func stop() {
        service.disconnect()
    }

    // MARK: - Private

    private func initializeQuotes() {
        quotes = tickers.map { Quote(ticker: $0) }
        for (index, ticker) in tickers.enumerated() {
            tickerIndexMap[ticker] = index
        }
    }

    // MARK: - WebSocketServiceDelegate

    func webSocketDidConnect() {
        service.subscribe(to: tickers)
    }

    func webSocketDidReceiveQuote(data: [String: Any]) {
        guard let ticker = data["c"] as? String,
              let index = tickerIndexMap[ticker] else { return }

        let oldPcp = quotes[index].percentChange
        quotes[index].merge(from: data)
        let newPcp = quotes[index].percentChange

        // Detect change direction
        let direction = detectDirection(oldPcp: oldPcp, newPcp: newPcp)
        if direction != .none {
            changeDirections[ticker] = direction
        }

        delegate?.quotesDidUpdate(at: [index])
    }

    func webSocketDidDisconnect(error: Error?) {
        // ViewModel stays passive; TradernetSocketService auto-reconnects
    }

    // MARK: - Direction Detection

    func detectDirection(oldPcp: Double?, newPcp: Double?) -> Quote.ChangeDirection {
        guard let newPcp = newPcp else { return .none }
        guard let oldPcp = oldPcp else {
            // First update — determine from sign
            if newPcp > 0 { return .up }
            if newPcp < 0 { return .down }
            return .none
        }
        if newPcp > oldPcp { return .up }
        if newPcp < oldPcp { return .down }
        return .none
    }
}
