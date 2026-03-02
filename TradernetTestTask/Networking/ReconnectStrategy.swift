//
//  ReconnectStrategy.swift
//  TradernetTestTask
//

import Foundation

struct ReconnectStrategy {
    let maxRetries: Int
    let baseInterval: TimeInterval
    let maxInterval: TimeInterval

    init(maxRetries: Int = 10, baseInterval: TimeInterval = 1, maxInterval: TimeInterval = 30) {
        self.maxRetries = maxRetries
        self.baseInterval = baseInterval
        self.maxInterval = maxInterval
    }

    func delay(forAttempt attempt: Int) -> TimeInterval {
        let delay = baseInterval * pow(2, Double(attempt))
        return min(delay, maxInterval)
    }

    func canRetry(attempt: Int) -> Bool {
        return attempt < maxRetries
    }
}
