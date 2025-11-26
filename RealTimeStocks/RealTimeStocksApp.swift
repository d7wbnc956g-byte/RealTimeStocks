//
//  RealTimeStocksApp.swift
//  RealTimeStocks
//
//  Created by Luke Barkhuizen on 2025/11/26.
//

import SwiftUI

@main
struct RealTimeStocksApp: App {
    @StateObject private var feedVM = FeedViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                FeedView()
                    .environmentObject(feedVM)
            }
            .onOpenURL { url in
                // Deep link: stocks://symbol/{SYMBOL}
                guard url.scheme == "stocks",
                      url.host == "symbol" else { return }
                let symbol = url.lastPathComponent.uppercased()
                feedVM.openDetailForDeepLink(symbol: symbol)
            }
        }
    }
}
