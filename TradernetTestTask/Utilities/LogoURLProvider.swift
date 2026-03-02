//
//  LogoURLProvider.swift
//  TradernetTestTask
//

import Foundation

protocol LogoURLProviding {
    func logoURL(for ticker: String) -> URL?
}

struct LogoURLProvider: LogoURLProviding {
    func logoURL(for ticker: String) -> URL? {
        let lowercased = ticker.lowercased()
        return URL(string: "https://tradernet.com/logos/get-logo-by-ticker?ticker=\(lowercased)")
    }
}
