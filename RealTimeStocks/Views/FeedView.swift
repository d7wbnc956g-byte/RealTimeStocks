//
//  FeedView.swift
//  RealTimeStocks
//
//  Created by Luke Barkhuizen on 2025/11/26.
//

import SwiftUI
import Combine

struct FeedView: View {
    @EnvironmentObject var feedVM: FeedViewModel
    @State private var path: [String] = [] // holds selected symbols for navigation
    @State private var selectionSymbol: String? = nil

    var body: some View {
        VStack {
            // Top bar with connection status and toggle
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .frame(width: 12, height: 12)
                        .foregroundColor(feedVM.connectionStatus ? .green : .red)
                    Text(feedVM.connectionStatus ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    if feedVM.isFeeding { feedVM.stopFeed() } else { feedVM.startFeed() }
                }) {
                    Text(feedVM.isFeeding ? "Stop Feed" : "Start Feed")
                        .bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).stroke())
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            List {
                ForEach(feedVM.stocks) { stock in
                    // Build lightweight StockViewModel for row
                    if let vm = feedVM.stockViewModel(for: stock.symbol) {
                        NavigationLink(value: vm.symbol) {
                            StockRowView(vm: vm)
                        }
                    } else {
                        EmptyView()
                    }
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: String.self) { symbol in
                if let vm = feedVM.stockViewModel(for: symbol) {
                    DetailView(viewModel: vm)
                } else {
                    Text("Unknown symbol")
                }
            }
            .onReceive(feedVM.$activeDetailSymbol.compactMap { $0 }) { symbol in
                path = [symbol]
            }
        }
        .navigationTitle("Live Prices")
        .onAppear {
            // nothing fancy — feed not started by default
        }
    }
}
