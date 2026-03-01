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

    init?(dictionary: [String: Any]) {
        guard let ticker = dictionary["c"] as? String, !ticker.isEmpty else {
            return nil
        }
        self.ticker = ticker
        self.lastTradePrice = dictionary["ltp"] as? Double
        self.percentChange = dictionary["pcp"] as? Double
        self.pointChange = dictionary["chg"] as? Double
        self.lastTradeExchange = dictionary["ltr"] as? String
        self.name = dictionary["name"] as? String
        self.minStep = dictionary["min_step"] as? Double
    }

    mutating func merge(from dictionary: [String: Any]) {
        if let ltp = dictionary["ltp"] as? Double {
            lastTradePrice = ltp
        }
        if let pcp = dictionary["pcp"] as? Double {
            percentChange = pcp
        }
        if let chg = dictionary["chg"] as? Double {
            pointChange = chg
        }
        if let ltr = dictionary["ltr"] as? String {
            lastTradeExchange = ltr
        }
        if let name = dictionary["name"] as? String {
            self.name = name
        }
        if let step = dictionary["min_step"] as? Double {
            minStep = step
        }
    }
}
