//
//  FeedViewModel.swift
//  RealTimeStocks
//
//  Created by Luke Barkhuizen on 2025/11/26.
//

import Foundation
import Combine

final class FeedViewModel: ObservableObject {
    // Published list that the feed observes
    @Published private(set) var stocks: [Stock] = []
    @Published var isFeeding: Bool = false
    @Published var connectionStatus: Bool = false
    @Published var activeDetailSymbol: String? = nil // for deep link navigation

    private var cancellables = Set<AnyCancellable>()
    private let websocket = WebSocketManager.shared
    private var generatorTimer: AnyCancellable?

    // sample 25 symbols
    private let symbolList = ["AAPL","GOOG","TSLA","AMZN","MSFT","NVDA","META","INTC","AMD","ORCL",
                              "NFLX","BABA","ADBE","CRM","UBER","LYFT","SQ","PYPL","SHOP","Z","IBM",
                              "V","MA","JPM","BAC"]

    init() {
        setupInitialStocks()
        bindWebSocket()
        websocket.isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectionStatus, on: self)
            .store(in: &cancellables)
    }

    private func setupInitialStocks() {
        stocks = symbolList.map { symbol in
            let starting = Double.random(in: 20...500)
            let desc = "Company \(symbol) — quick description and market context."
            return Stock(symbol: symbol, price: starting, description: desc)
        }
    }

    private func bindWebSocket() {
        websocket.incoming
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.handleIncoming(text: text)
            }
            .store(in: &cancellables)
    }

    private func handleIncoming(text: String) {
        // Expecting JSON like {"symbol":"AAPL","price":123.45,"timestamp":...}
        guard let data = text.data(using: .utf8) else { return }
        do {
            let decoded = try JSONDecoder().decode(EchoMessage.self, from: data)
            guard let symbol = decoded.symbol else { return }
            if let index = stocks.firstIndex(where: { $0.symbol == symbol }) {
                var copy = stocks[index]
                copy.previousPrice = copy.price
                copy.price = decoded.price ?? copy.price
                stocks[index] = copy
                // ensure UI updates and sorted order
                sortStocks()
            }
        } catch {
            // The postman echo may wrap messages differently. Try a fuzzy parse:
            if let fallback = try? JSONDecoder().decode(EchoMessageFallback.self, from: data) {
                // fallback.message contains our original json as string
                if let innerData = fallback.message.data(using: .utf8) {
                    if let inner = try? JSONDecoder().decode(EchoMessage.self, from: innerData),
                       let symbol = inner.symbol,
                       let index = stocks.firstIndex(where: { $0.symbol == symbol }) {
                        var copy = stocks[index]
                        copy.previousPrice = copy.price
                        copy.price = inner.price ?? copy.price
                        stocks[index] = copy
                        sortStocks()
                    }
                }
            } else {
                // ignore other messages
            }
        }
    }

    private func sortStocks() {
        stocks.sort { $0.price > $1.price }
    }

    // Start the generation + websocket flow
    func startFeed() {
        guard !isFeeding else { return }
        websocket.connect()
        isFeeding = true

        // Timer every 2s: generate update for every symbol and send via WS
        generatorTimer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.generateAndSendUpdates()
            }
    }

    func stopFeed() {
        isFeeding = false
        generatorTimer?.cancel()
        generatorTimer = nil
        websocket.disconnect()
    }

    private func generateAndSendUpdates() {
        for symbol in symbolList {
            guard let index = stocks.firstIndex(where: { $0.symbol == symbol }) else { continue }
            var stock = stocks[index]
            // random small delta: +/- up to 2%
            let pct = Double.random(in: -0.02...0.02)
            let newPrice = max(0.01, stock.price * (1 + pct))
            let message = OutgoingMessage(symbol: symbol, price: round(newPrice * 100) / 100.0, timestamp: ISO8601DateFormatter().string(from: Date()))
            if let payload = try? JSONEncoder().encode(message),
               let json = String(data: payload, encoding: .utf8) {
                websocket.send(message: json)
            }
        }
    }

    // For deep linking
    func openDetailForDeepLink(symbol: String) {
        // if symbol exists, set activeDetailSymbol — the view can observe and navigate
        if stocks.contains(where: { $0.symbol == symbol }) {
            activeDetailSymbol = symbol
        }
    }

    // Helpers for View
    func stockViewModel(for symbol: String) -> StockViewModel? {
        guard let stock = stocks.first(where: { $0.symbol == symbol }) else { return nil }
        return StockViewModel(initialStock: stock, feed: self)
    }

    // Simple structs for JSON parsing
    private struct EchoMessage: Codable {
        var symbol: String?
        var price: Double?
        var timestamp: String?
    }
    private struct EchoMessageFallback: Codable {
        var message: String
    }
    private struct OutgoingMessage: Codable {
        let symbol: String
        let price: Double
        let timestamp: String
    }
}
