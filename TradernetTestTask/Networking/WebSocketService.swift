//
//  WebSocketService.swift
//  TradernetTestTask
//

import Foundation

protocol WebSocketServiceDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidReceiveQuote(data: [String: Any])
    func webSocketDidDisconnect(error: Error?)
    func webSocketDidExhaustRetries()
}

protocol WebSocketService: AnyObject {
    var delegate: WebSocketServiceDelegate? { get set }
    func connect()
    func disconnect()
    func subscribe(to tickers: [String])
}
