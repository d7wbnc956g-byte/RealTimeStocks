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
}
