//
//  FeedViewModelTests.swift
//  RealTimeStocks
//
//  Created by Luke Barkhuizen on 2025/11/26.
//

import XCTest
import Combine
@testable import RealTimeStocks

@MainActor
final class FeedViewModelTests: XCTestCase {

    var viewModel: FeedViewModel!
    var mockWS: MockWebSocketManager!
    var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        mockWS = MockWebSocketManager()
        viewModel = FeedViewModel(websocket: mockWS)
    }

    override func tearDown() {
        viewModel = nil
        mockWS = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func testInitialStocks() {
        XCTAssertEqual(viewModel.stocks.count, 25, "Should initialize 25 stocks")
        XCTAssertTrue(viewModel.stocks.allSatisfy { !$0.symbol.isEmpty })
    }

    func testStartAndStopFeed() {
        XCTAssertFalse(viewModel.isFeeding)
        viewModel.startFeed()
        XCTAssertTrue(viewModel.isFeeding)
        viewModel.stopFeed()
        XCTAssertFalse(viewModel.isFeeding)
    }

    func testDeepLinkOpensDetail() {
        let symbol = viewModel.stocks[0].symbol
        viewModel.openDetailForDeepLink(symbol: symbol)
        XCTAssertEqual(viewModel.activeDetailSymbol, symbol)
    }

    func testSortingAfterManualUpdate() {
        // Pick a stock and increase its price above the current highest
        let highestBefore = viewModel.stocks.max(by: { $0.price < $1.price })!
        let target = viewModel.stocks[0]
        let newPrice = highestBefore.price + 50

        // Manually send a WebSocket message via mock
        let message = """
        {"symbol":"\(target.symbol)","price":\(newPrice),"timestamp":"\(Date())"}
        """
        mockWS.incoming.send(message)

        // Wait for Combine to propagate
        let expectation = XCTestExpectation(description: "Wait for stock update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.stocks.first?.symbol, target.symbol, "Updated stock should now be first after price increase")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testGenerateAndSendUpdates() {
        // simulate manually sending messages for all stocks
        viewModel.stocks.forEach { stock in
            let message = """
            {"symbol":"\(stock.symbol)","price":\(stock.price + 1),"timestamp":"\(Date())"}
            """
            viewModel.websocket.send(message: message)
        }

        XCTAssertEqual(mockWS.sentMessages.count, 25, "Should send a message for every symbol")
    }
    
    func testSetupInitialStocksLoadsStocksWithPreviousPrices() throws {
           let vm = FeedViewModel(websocket: MockWebSocketManager())

           XCTAssertEqual(vm.stocks.count, 25, "Should load 25 stocks from JSON")

           let ids = vm.stocks.map { $0.id }
           XCTAssertEqual(Set(ids).count, 25, "Stock IDs should be unique")

           let missingPrev = vm.stocks.contains { $0.previousPrice == nil }
           XCTAssertFalse(missingPrev, "All stocks should have previousPrice from JSON")

           let first = vm.stocks.first!
           XCTAssertEqual(first.id, 1)
           XCTAssertEqual(first.symbol, "AAPL")
           XCTAssertEqual(first.price, 198.45)
           XCTAssertEqual(first.previousPrice, 197.30)
           XCTAssertEqual(first.description, "Apple Inc. — Designs, manufactures, and markets consumer electronics, software, and online services.")

           let last = vm.stocks.last!
           XCTAssertEqual(last.id, 25)
           XCTAssertEqual(last.symbol, "BAC")
           XCTAssertEqual(last.price, 33.90)
           XCTAssertEqual(last.previousPrice, 33.50)
       }
}
