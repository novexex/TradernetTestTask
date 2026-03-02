//
//  L10n.swift
//  TradernetTestTask
//

import Foundation

enum L10n {
    enum Quotes {
        static let title = NSLocalizedString("quotes.title", comment: "")
        static let retry = NSLocalizedString("quotes.retry", comment: "")
        static let connectionFailed = NSLocalizedString("quotes.connectionFailed", comment: "")
    }
    enum QuoteDetail {
        static let ticker = NSLocalizedString("quoteDetail.ticker", comment: "")
        static let exchange = NSLocalizedString("quoteDetail.exchange", comment: "")
        static let name = NSLocalizedString("quoteDetail.name", comment: "")
        static let lastTradePrice = NSLocalizedString("quoteDetail.lastTradePrice", comment: "")
        static let changePercent = NSLocalizedString("quoteDetail.changePercent", comment: "")
        static let changePoints = NSLocalizedString("quoteDetail.changePoints", comment: "")
        static let minStep = NSLocalizedString("quoteDetail.minStep", comment: "")
    }
}
