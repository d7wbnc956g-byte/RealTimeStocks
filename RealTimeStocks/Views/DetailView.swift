//
//  DetailView.swift
//  RealTimeStocks
//
//  Created by Luke Barkhuizen on 2025/11/26.
//

import SwiftUI

struct DetailView: View {
    @ObservedObject var viewModel: StockViewModel
    @State private var flashColor: Color = .clear
    @State private var lastPrice: Double?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(viewModel.symbol)
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Image(systemName: iconForDirection(viewModel.changeDirection))
                    .foregroundColor(colorForDirection(viewModel.changeDirection))
            }
            .padding(.horizontal)

            Text(viewModel.priceText)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .padding(.vertical)

            Text(viewModel.changeText)
                .font(.subheadline)
                .foregroundColor(colorForDirection(viewModel.changeDirection))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("About \(viewModel.symbol)")
                        .font(.headline)
                    Text(viewModel.descriptionText)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            Spacer()
        }
        .background(flashColor.opacity(0.15))
        .onReceive(viewModel.$stock) { stock in
            // flash background for 1s on change
            if let last = lastPrice {
                if stock.price > last {
                    flashOnce(.green)
                } else if stock.price < last {
                    flashOnce(.red)
                }
            }
            lastPrice = stock.price
        }
        .navigationTitle(viewModel.symbol)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func flashOnce(_ color: Color) {
        withAnimation(.easeOut(duration: 0.12)) {
            flashColor = color
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.25)) {
                flashColor = .clear
            }
        }
    }

    private func iconForDirection(_ dir: Stock.ChangeDirection) -> String {
        switch dir {
        case .up: return "arrow.up.right.circle.fill"
        case .down: return "arrow.down.right.circle.fill"
        case .none: return "minus.circle"
        }
    }

    private func colorForDirection(_ dir: Stock.ChangeDirection) -> Color {
        switch dir {
        case .up: return .green
        case .down: return .red
        case .none: return .gray
        }
    }
}
