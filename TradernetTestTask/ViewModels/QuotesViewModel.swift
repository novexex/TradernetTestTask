//
//  QuotesViewModel.swift
//  TradernetTestTask
//

import Foundation

protocol QuotesViewModelDelegate: AnyObject {
    func quotesDidUpdate(at indexes: [Int])
    func quotesDidReload()
    func quotesDidFailToConnect()
    func quotesDidConnect()
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

    /// Per-ticker observers for detail screen live updates
    private var quoteObservers: [UUID: (ticker: String, handler: (Quote) -> Void)] = [:]

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

    func retry() {
        service.connect()
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
        delegate?.quotesDidConnect()
    }

    func webSocketDidReceiveQuote(data: [String: Any]) {
        guard let ticker = data["c"] as? String,
              let index = tickerIndexMap[ticker] else { return }

        let oldPcp = quotes[index].percentChange
        quotes[index].merge(from: data)
        let newPcp = quotes[index].percentChange

        // Detect change direction
        let direction = detectDirection(oldPcp: oldPcp, newPcp: newPcp)
        changeDirections[ticker] = direction

        delegate?.quotesDidUpdate(at: [index])

        let updatedQuote = quotes[index]
        for (_, observer) in quoteObservers where observer.ticker == ticker {
            observer.handler(updatedQuote)
        }
    }

    func webSocketDidDisconnect(error: Error?) {
        // ViewModel stays passive; TradernetSocketService auto-reconnects
    }

    func webSocketDidExhaustRetries() {
        delegate?.quotesDidFailToConnect()
    }

    // MARK: - Quote Observation

    func observeQuote(for ticker: String, handler: @escaping (Quote) -> Void) -> UUID {
        let id = UUID()
        quoteObservers[id] = (ticker: ticker, handler: handler)
        return id
    }

    func removeObservation(_ id: UUID) {
        quoteObservers.removeValue(forKey: id)
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
