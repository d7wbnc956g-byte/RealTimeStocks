//
//  Stocks.swift
//  RealTimeStocks
//
//  Created by Luke Barkhuizen on 2025/11/26.
//

import Foundation

struct Stock: Identifiable, Codable, Equatable {
    var id: Int
    var symbol: String
    var price: Double
    var previousPrice: Double?
    var description: String

    init(symbol: String, price: Double, description: String = "") {
        self.id = Int()
        self.symbol = symbol
        self.price = price
        self.previousPrice = nil
        self.description = description
    }

    var change: Double {
        guard let prev = previousPrice else { return 0 }
        return price - prev
    }

    var changeDirection: ChangeDirection {
        guard let prev = previousPrice else { return .none }
        if price > prev { return .up }
        if price < prev { return .down }
        return .none
    }

    enum ChangeDirection {
        case up, down, none
    }
}
