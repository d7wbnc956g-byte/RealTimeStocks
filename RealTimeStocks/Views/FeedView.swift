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
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Connection & Start/Stop controls
                    HStack {
                        Circle()
                            .frame(width: 12, height: 12)
                            .foregroundColor(feedVM.connectionStatus ? .green : .red)
                        Text(feedVM.connectionStatus ? "Connected" : "Disconnected")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            feedVM.isFeeding ? feedVM.stopFeed() : feedVM.startFeed()
                        } label: {
                            Text(feedVM.isFeeding ? "Stop" : "Start")
                                .font(.subheadline).bold()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(feedVM.isFeeding ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(feedVM.isFeeding ? Color.red : Color.green, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                    // MARK: - Stock list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(feedVM.stocks, id: \.id) { stock in
                                if let vm = feedVM.stockViewModel(for: stock.symbol) {
                                    NavigationLink(value: vm.symbol) {
                                        HStack {
                                            Text(vm.symbol)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            HStack(spacing: 6) {
                                                Text(vm.priceText)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Image(systemName:
                                                    vm.changeDirection == .up ? "arrow.up" :
                                                    vm.changeDirection == .down ? "arrow.down" : "minus"
                                                )
                                                .foregroundColor(
                                                    vm.changeDirection == .up ? .green :
                                                    vm.changeDirection == .down ? .red : .gray
                                                )
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(Color.white)
                                                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                                        )
                                        .padding(.horizontal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                    .navigationDestination(for: String.self) { symbol in
                        if let vm = feedVM.stockViewModel(for: symbol) {
                            DetailView(viewModel: vm)
                        } else {
                            Text("Unknown symbol")
                        }
                    }
                }
            }
            .navigationTitle("Live Prices")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
