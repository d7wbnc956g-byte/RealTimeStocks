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
    @Published var stocks: [Stock] = []
    @Published var isFeeding: Bool = false
    @Published var connectionStatus: Bool = false
    @Published var activeDetailSymbol: String? = nil // for deep link navigation

    private var cancellables = Set<AnyCancellable>()
    private var generatorTimer: AnyCancellable?
    private let symbolList = ["AAPL","GOOG","TSLA","AMZN","MSFT","NVDA","META","INTC","AMD","ORCL",
                              "NFLX","BABA","ADBE","CRM","UBER","LYFT","SQ","PYPL","SHOP","Z","IBM",
                              "V","MA","JPM","BAC"]

    // Injected WebSocketManagerType for testability
    var websocket: WebSocketManagerType

    init(websocket: WebSocketManagerType = WebSocketManager.shared) {
        self.websocket = websocket
        setupInitialStocks()
        bindWebSocket()
        websocket.isConnected
            .receive(on: RunLoop.main)
            .assign(to: \.connectionStatus, on: self)
            .store(in: &cancellables)
    }

    private func setupInitialStocks() {
        // Deterministic random prices; can override in tests
        stocks = symbolList.map { symbol in
            let starting = Double.random(in: 20...500)
            let desc = "Company \(symbol) — quick description and market context."
            return Stock(symbol: symbol, price: starting, description: desc)
        }
    }

    private func bindWebSocket() {
        websocket.incoming
            .sink { [weak self] text in
                self?.handleIncoming(text: text)
            }
            .store(in: &cancellables)
    }

    // Make public for test injection, still safe
    func handleIncoming(text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        func process(symbol: String, price: Double?) {
            DispatchQueue.main.async { [weak self] in
                self?.updateStock(symbol: symbol, newPrice: price)
            }
        }

        do {
            let decoded = try JSONDecoder().decode(EchoMessage.self, from: data)
            if let symbol = decoded.symbol {
                process(symbol: symbol, price: decoded.price)
            }
        } catch {
            if let fallback = try? JSONDecoder().decode(EchoMessageFallback.self, from: data),
               let innerData = fallback.message.data(using: .utf8),
               let inner = try? JSONDecoder().decode(EchoMessage.self, from: innerData),
               let symbol = inner.symbol {
                process(symbol: symbol, price: inner.price)
            }
        }
    }

    private func updateStock(symbol: String, newPrice: Double?) {
        guard let index = stocks.firstIndex(where: { $0.symbol == symbol }) else { return }
        var copy = stocks[index]
        copy.previousPrice = copy.price
        if let price = newPrice { copy.price = price }
        stocks[index] = copy
        sortStocks()
    }

    private func sortStocks() {
        stocks.sort { $0.price > $1.price }
    }

    func startFeed() {
        guard !isFeeding else { return }
        websocket.connect()
        isFeeding = true

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
            let stock = stocks[index]
            let pct = Double.random(in: -0.02...0.02)
            let newPrice = max(0.01, stock.price * (1 + pct))
            let message = OutgoingMessage(symbol: symbol,
                                          price: round(newPrice*100)/100.0,
                                          timestamp: ISO8601DateFormatter().string(from: Date()))
            if let payload = try? JSONEncoder().encode(message),
               let json = String(data: payload, encoding: .utf8) {
                websocket.send(message: json)
            }
        }
    }

    func openDetailForDeepLink(symbol: String) {
        if stocks.contains(where: { $0.symbol == symbol }) {
            activeDetailSymbol = symbol
        }
    }

    func stockViewModel(for symbol: String) -> StockViewModel? {
        guard let stock = stocks.first(where: { $0.symbol == symbol }) else { return nil }
        return StockViewModel(initialStock: stock, feed: self)
    }

    // MARK: - Codable structs
    struct EchoMessage: Codable {
        var symbol: String?
        var price: Double?
        var timestamp: String?
    }

    struct EchoMessageFallback: Codable {
        var message: String
    }

    struct OutgoingMessage: Codable {
        let symbol: String
        let price: Double
        let timestamp: String
    }
}
