//
//  Constants.swift
//  TradernetTestTask
//

import Foundation

enum Constants {
    static let webSocketURL = "wss://wss.tradernet.com/socket.io/?EIO=4&transport=websocket"

    static let tickers = [
        "RSTI",
        "GAZP",
        "MRKZ",
        "RUAL",
        "HYDR",
        "MRKS",
        "SBER",
        "FEES",
        "TGKA",
        "VTBR",
        "ANH.US",
        "BANE",
        "ALRS",
        "LKOH",
        "GMKN",
        "MTLR",
        "TATN",
        "NLMK",
        "PLZL",
        "YNDX",
        "MGNT",
        "ROSN",
        "AFLT",
        "NVTK",
        "MOEX",
        "SMLT",
        "BANEP",
        "MTSS",
        "IRAO",
        "SIBN"
    ]

    static func logoURL(for ticker: String) -> URL? {
        let lowercased = ticker.lowercased()
        return URL(string: "https://tradernet.com/logos/get-logo-by-ticker?ticker=\(lowercased)")
    }
}
