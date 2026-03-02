//
//  QuoteMapper.swift
//  TradernetTestTask
//

protocol QuoteMapping {
    func quote(from dictionary: [String: Any]) -> Quote?
    func merge(_ quote: Quote, with dictionary: [String: Any]) -> Quote
}

struct QuoteMapper: QuoteMapping {

    func quote(from dictionary: [String: Any]) -> Quote? {
        guard let ticker = dictionary[QuoteKey.ticker.rawValue] as? String, !ticker.isEmpty else {
            return nil
        }
        var quote = Quote(ticker: ticker)
        quote.lastTradePrice = dictionary[QuoteKey.lastTradePrice.rawValue] as? Double
        quote.percentChange = dictionary[QuoteKey.percentChange.rawValue] as? Double
        quote.pointChange = dictionary[QuoteKey.pointChange.rawValue] as? Double
        quote.lastTradeExchange = dictionary[QuoteKey.lastTradeExchange.rawValue] as? String
        quote.name = dictionary[QuoteKey.name.rawValue] as? String
        quote.minStep = dictionary[QuoteKey.minStep.rawValue] as? Double
        return quote
    }

    func merge(_ quote: Quote, with dictionary: [String: Any]) -> Quote {
        var updated = quote
        if let ltp = dictionary[QuoteKey.lastTradePrice.rawValue] as? Double {
            updated.lastTradePrice = ltp
        }
        if let pcp = dictionary[QuoteKey.percentChange.rawValue] as? Double {
            updated.percentChange = pcp
        }
        if let chg = dictionary[QuoteKey.pointChange.rawValue] as? Double {
            updated.pointChange = chg
        }
        if let ltr = dictionary[QuoteKey.lastTradeExchange.rawValue] as? String {
            updated.lastTradeExchange = ltr
        }
        if let name = dictionary[QuoteKey.name.rawValue] as? String {
            updated.name = name
        }
        if let step = dictionary[QuoteKey.minStep.rawValue] as? Double {
            updated.minStep = step
        }
        return updated
    }
}
