//
//  QuoteTests.swift
//  TradernetTestTaskTests
//

import XCTest
@testable import TradernetTestTask

final class QuoteTests: XCTestCase {

    // MARK: - Init from dictionary

    func testInitFromFullDictionary() {
        let dict: [String: Any] = [
            "c": "AAPL.US",
            "ltp": 150.25,
            "pcp": 2.35,
            "chg": 3.45,
            "ltr": "NYSE",
            "name": "Apple Inc",
            "min_step": 0.01
        ]

        let quote = Quote(dictionary: dict)

        XCTAssertNotNil(quote)
        XCTAssertEqual(quote?.ticker, "AAPL.US")
        XCTAssertEqual(quote?.lastTradePrice, 150.25)
        XCTAssertEqual(quote?.percentChange, 2.35)
        XCTAssertEqual(quote?.pointChange, 3.45)
        XCTAssertEqual(quote?.lastTradeExchange, "NYSE")
        XCTAssertEqual(quote?.name, "Apple Inc")
        XCTAssertEqual(quote?.minStep, 0.01)
    }

    func testInitReturnsNilForMissingTicker() {
        let dict: [String: Any] = ["ltp": 100.0]
        XCTAssertNil(Quote(dictionary: dict))
    }

    func testInitReturnsNilForEmptyTicker() {
        let dict: [String: Any] = ["c": "", "ltp": 100.0]
        XCTAssertNil(Quote(dictionary: dict))
    }

    func testInitWithMinimalDictionary() {
        let dict: [String: Any] = ["c": "SBER"]
        let quote = Quote(dictionary: dict)

        XCTAssertNotNil(quote)
        XCTAssertEqual(quote?.ticker, "SBER")
        XCTAssertNil(quote?.lastTradePrice)
        XCTAssertNil(quote?.percentChange)
        XCTAssertNil(quote?.pointChange)
        XCTAssertNil(quote?.lastTradeExchange)
        XCTAssertNil(quote?.name)
        XCTAssertNil(quote?.minStep)
    }

    // MARK: - Merge

    func testMergeUpdatesOnlyProvidedFields() {
        var quote = Quote(dictionary: [
            "c": "GAZP",
            "ltp": 200.0,
            "pcp": 1.5,
            "name": "Gazprom"
        ])!

        quote.merge(from: ["ltp": 201.0, "chg": 1.0])

        XCTAssertEqual(quote.lastTradePrice, 201.0)
        XCTAssertEqual(quote.pointChange, 1.0)
        // Unchanged fields
        XCTAssertEqual(quote.percentChange, 1.5)
        XCTAssertEqual(quote.name, "Gazprom")
    }

    func testMergeAllFields() {
        var quote = Quote(ticker: "TEST")

        quote.merge(from: [
            "ltp": 50.0,
            "pcp": -0.5,
            "chg": -0.25,
            "ltr": "MCX",
            "name": "Test Corp",
            "min_step": 0.1
        ])

        XCTAssertEqual(quote.lastTradePrice, 50.0)
        XCTAssertEqual(quote.percentChange, -0.5)
        XCTAssertEqual(quote.pointChange, -0.25)
        XCTAssertEqual(quote.lastTradeExchange, "MCX")
        XCTAssertEqual(quote.name, "Test Corp")
        XCTAssertEqual(quote.minStep, 0.1)
    }

    // MARK: - Change Direction

    func testChangeDirectionUp() {
        var quote = Quote(ticker: "X")
        quote.merge(from: ["pcp": 1.5])
        XCTAssertEqual(quote.changeDirection, .up)
    }

    func testChangeDirectionDown() {
        var quote = Quote(ticker: "X")
        quote.merge(from: ["pcp": -0.3])
        XCTAssertEqual(quote.changeDirection, .down)
    }

    func testChangeDirectionNone() {
        var quote = Quote(ticker: "X")
        quote.merge(from: ["pcp": 0.0])
        XCTAssertEqual(quote.changeDirection, .none)
    }

    func testChangeDirectionNilPercent() {
        let quote = Quote(ticker: "X")
        XCTAssertEqual(quote.changeDirection, .none)
    }
}
