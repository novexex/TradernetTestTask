//
//  Constants.swift
//  TradernetTestTask
//

import Foundation

enum Constants {
    static let webSocketURL = "wss://wss.tradernet.com/socket.io/?EIO=4&transport=websocket"

    static let tickers = [
        "SP500.IDX",
        "AAPL.US",
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
        "VICL.US",
        "BURG.US",
        "NBL.US",
        "YETI.US",
        "WSFS.US",
        "NIO.US",
        "DXC.US",
        "MIC.US",
        "HSBC.US",
        "EXPN.EU",
        "GSK.EU",
        "SHP.EU",
        "MAN.EU",
        "DB1.EU",
        "MUV2.EU",
        "TATE.EU",
        "KGF.EU",
        "MGGT.EU",
        "SGGD.EU"
    ]

    static func logoURL(for ticker: String) -> URL? {
        let lowercased = ticker.lowercased()
        return URL(string: "https://tradernet.com/logos/get-logo-by-ticker?ticker=\(lowercased)")
    }
}
