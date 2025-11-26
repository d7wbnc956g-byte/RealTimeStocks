//
//  StockViewModel.swift
//  RealTimeStocks
//
//  Created by Luke Barkhuizen on 2025/11/26.
//

import Foundation
import Combine

final class StockViewModel: ObservableObject, Identifiable {
    @Published private(set) var stock: Stock
    private var feed: FeedViewModel
    private var cancellables = Set<AnyCancellable>()

    var id: UUID { stock.id }

    init(initialStock: Stock, feed: FeedViewModel) {
        self.stock = initialStock
        self.feed = feed

        // Observe feed stocks array for updates relevant to this symbol
        feed.$stocks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stocks in
                guard let self = self,
                      let updated = stocks.first(where: { $0.symbol == self.stock.symbol }) else { return }
                self.stock = updated
            }
            .store(in: &cancellables)
    }

    var symbol: String { stock.symbol }
    var priceText: String { PriceFormatter.format(price: stock.price) }
    var changeDirection: Stock.ChangeDirection { stock.changeDirection }
    var changeText: String {
        guard let prev = stock.previousPrice else { return "—" }
        let diff = stock.price - prev
        return String(format: "%+.2f (%.2f%%)", diff, (diff / prev) * 100)
    }
    var descriptionText: String { stock.description }
}
