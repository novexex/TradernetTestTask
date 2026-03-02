//
//  QuotesViewModelTests.swift
//  TradernetTestTaskTests
//

import XCTest
@testable import TradernetTestTask

final class QuotesViewModelTests: XCTestCase {

    private var mockService: MockWebSocketService!
    private var viewModel: QuotesViewModel!
    private var delegateSpy: ViewModelDelegateSpy!

    override func setUp() {
        super.setUp()
        mockService = MockWebSocketService()
        viewModel = QuotesViewModel(service: mockService, tickers: ["AAPL", "GAZP", "SBER"])
        delegateSpy = ViewModelDelegateSpy()
        viewModel.delegate = delegateSpy
    }

    override func tearDown() {
        mockService = nil
        viewModel = nil
        delegateSpy = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialQuotesMatchTickers() {
        XCTAssertEqual(viewModel.quotes.count, 3)
        XCTAssertEqual(viewModel.quotes[0].ticker, "AAPL")
        XCTAssertEqual(viewModel.quotes[1].ticker, "GAZP")
        XCTAssertEqual(viewModel.quotes[2].ticker, "SBER")
    }

    // MARK: - Connection

    func testStartCallsConnect() {
        viewModel.start()
        XCTAssertEqual(mockService.connectCallCount, 1)
    }

    func testStopCallsDisconnect() {
        viewModel.stop()
        XCTAssertEqual(mockService.disconnectCallCount, 1)
    }

    func testSubscribesOnConnect() {
        viewModel.start()
        mockService.simulateConnect()
        XCTAssertEqual(mockService.subscribedTickers, ["AAPL", "GAZP", "SBER"])
    }

    // MARK: - Quote Updates

    func testQuoteUpdateMergesData() {
        mockService.simulateQuote(data: [
            "c": "GAZP",
            "ltp": 201.73,
            "pcp": 0.86,
            "chg": 1.73,
            "ltr": "MCX",
            "name": "GAZPROM"
        ])

        XCTAssertEqual(viewModel.quotes[1].lastTradePrice, 201.73)
        XCTAssertEqual(viewModel.quotes[1].percentChange, 0.86)
        XCTAssertEqual(viewModel.quotes[1].name, "GAZPROM")
    }

    func testDelegateCalledWithCorrectIndex() {
        mockService.simulateQuote(data: ["c": "SBER", "ltp": 237.0])
        XCTAssertEqual(delegateSpy.lastUpdatedIndexes, [2])
    }

    func testUnknownTickerIgnored() {
        mockService.simulateQuote(data: ["c": "UNKNOWN", "ltp": 100.0])
        XCTAssertNil(delegateSpy.lastUpdatedIndexes)
    }

    func testPartialMergePreservesExistingFields() {
        // First update with full data
        mockService.simulateQuote(data: [
            "c": "AAPL",
            "ltp": 150.0,
            "pcp": 2.0,
            "name": "Apple"
        ])

        // Partial update — only price changes
        mockService.simulateQuote(data: [
            "c": "AAPL",
            "ltp": 151.0
        ])

        XCTAssertEqual(viewModel.quotes[0].lastTradePrice, 151.0)
        XCTAssertEqual(viewModel.quotes[0].percentChange, 2.0)  // Preserved
        XCTAssertEqual(viewModel.quotes[0].name, "Apple")        // Preserved
    }

    // MARK: - Direction Detection

    func testDetectDirectionUpFromNil() {
        let direction = viewModel.detectDirection(oldPcp: nil, newPcp: 1.5)
        XCTAssertEqual(direction, .up)
    }

    func testDetectDirectionDownFromNil() {
        let direction = viewModel.detectDirection(oldPcp: nil, newPcp: -0.5)
        XCTAssertEqual(direction, .down)
    }

    func testDetectDirectionUpFromIncrease() {
        let direction = viewModel.detectDirection(oldPcp: 1.0, newPcp: 2.0)
        XCTAssertEqual(direction, .up)
    }

    func testDetectDirectionDownFromDecrease() {
        let direction = viewModel.detectDirection(oldPcp: 2.0, newPcp: 1.0)
        XCTAssertEqual(direction, .down)
    }

    func testDetectDirectionNoneWhenSame() {
        let direction = viewModel.detectDirection(oldPcp: 1.0, newPcp: 1.0)
        XCTAssertEqual(direction, .none)
    }

    func testDetectDirectionNoneForNilNew() {
        let direction = viewModel.detectDirection(oldPcp: 1.0, newPcp: nil)
        XCTAssertEqual(direction, .none)
    }

    func testChangeDirectionStoredOnUpdate() {
        mockService.simulateQuote(data: ["c": "AAPL", "pcp": 2.0])
        XCTAssertEqual(viewModel.changeDirections["AAPL"], .up)
    }

    // MARK: - Reconnection

    func testResubscribesAfterReconnect() {
        viewModel.start()
        mockService.simulateConnect()
        XCTAssertEqual(mockService.subscribedTickers, ["AAPL", "GAZP", "SBER"])

        // Simulate disconnect + reconnect
        mockService.resetSubscribedTickers()
        mockService.simulateDisconnect()
        mockService.simulateConnect()
        XCTAssertEqual(mockService.subscribedTickers, ["AAPL", "GAZP", "SBER"])
    }

    func testQuotesPreservedAfterDisconnect() {
        mockService.simulateQuote(data: ["c": "AAPL", "ltp": 150.0, "name": "Apple"])
        mockService.simulateDisconnect()
        XCTAssertEqual(viewModel.quotes[0].lastTradePrice, 150.0)
        XCTAssertEqual(viewModel.quotes[0].name, "Apple")
    }
}

// MARK: - Delegate Spy

private final class ViewModelDelegateSpy: QuotesViewModelDelegate {
    var lastUpdatedIndexes: [Int]?
    var reloadCalled = false

    func quotesDidUpdate(at indexes: [Int]) {
        lastUpdatedIndexes = indexes
    }

    func quotesDidReload() {
        reloadCalled = true
    }
}
