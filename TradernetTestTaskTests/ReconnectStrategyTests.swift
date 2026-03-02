//
//  ReconnectStrategyTests.swift
//  TradernetTestTaskTests
//

import XCTest
@testable import TradernetTestTask

final class ReconnectStrategyTests: XCTestCase {

    func testDefaultValues() {
        let strategy = ReconnectStrategy()
        XCTAssertEqual(strategy.maxRetries, 10)
        XCTAssertEqual(strategy.baseInterval, 1)
        XCTAssertEqual(strategy.maxInterval, 30)
    }

    func testCustomValues() {
        let strategy = ReconnectStrategy(maxRetries: 5, baseInterval: 2, maxInterval: 60)
        XCTAssertEqual(strategy.maxRetries, 5)
        XCTAssertEqual(strategy.baseInterval, 2)
        XCTAssertEqual(strategy.maxInterval, 60)
    }

    func testDelayExponentialBackoff() {
        let strategy = ReconnectStrategy(baseInterval: 1, maxInterval: 30)
        XCTAssertEqual(strategy.delay(forAttempt: 0), 1)    // 1 * 2^0 = 1
        XCTAssertEqual(strategy.delay(forAttempt: 1), 2)    // 1 * 2^1 = 2
        XCTAssertEqual(strategy.delay(forAttempt: 2), 4)    // 1 * 2^2 = 4
        XCTAssertEqual(strategy.delay(forAttempt: 3), 8)    // 1 * 2^3 = 8
        XCTAssertEqual(strategy.delay(forAttempt: 4), 16)   // 1 * 2^4 = 16
    }

    func testDelayCappedAtMaxInterval() {
        let strategy = ReconnectStrategy(baseInterval: 1, maxInterval: 30)
        XCTAssertEqual(strategy.delay(forAttempt: 5), 30)   // 1 * 2^5 = 32, capped to 30
        XCTAssertEqual(strategy.delay(forAttempt: 10), 30)  // capped to 30
    }

    func testCanRetryWithinLimit() {
        let strategy = ReconnectStrategy(maxRetries: 3)
        XCTAssertTrue(strategy.canRetry(attempt: 0))
        XCTAssertTrue(strategy.canRetry(attempt: 1))
        XCTAssertTrue(strategy.canRetry(attempt: 2))
    }

    func testCannotRetryAtLimit() {
        let strategy = ReconnectStrategy(maxRetries: 3)
        XCTAssertFalse(strategy.canRetry(attempt: 3))
    }

    func testCannotRetryBeyondLimit() {
        let strategy = ReconnectStrategy(maxRetries: 3)
        XCTAssertFalse(strategy.canRetry(attempt: 5))
    }
}
