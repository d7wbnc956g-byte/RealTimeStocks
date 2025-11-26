//
//  PriceFormatter.swift
//  RealTimeStocks
//
//  Created by Luke Barkhuizen on 2025/11/26.
//

import Foundation

struct PriceFormatter {
    static func format(price: Double) -> String {
        if price >= 1000 {
            return String(format: "$%.2f", price)
        } else {
            return String(format: "$%.2f", price)
        }
    }
}
