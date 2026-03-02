//
//  Quote.swift
//  TradernetTestTask
//

import Foundation

struct Quote: Equatable {
    let ticker: String
    var lastTradePrice: Double?
    var percentChange: Double?
    var pointChange: Double?
    var lastTradeExchange: String?
    var name: String?
    var minStep: Double?

    enum ChangeDirection {
        case up
        case down
        case none
    }

    var changeDirection: ChangeDirection {
        guard let pcp = percentChange else { return .none }
        if pcp > 0 { return .up }
        if pcp < 0 { return .down }
        return .none
    }

    init(ticker: String) {
        self.ticker = ticker
    }
}
