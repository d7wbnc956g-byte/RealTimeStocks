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
    @State private var flashDirection: Stock.ChangeDirection = .none

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemGray6), Color(.systemGray5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.symbol)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text(viewModel.changeText)
                            .font(.subheadline)
                            .foregroundColor(colorForDirection(viewModel.changeDirection))
                    }

                    Spacer()

                    Image(systemName: iconForDirection(flashDirection != .none ? flashDirection : viewModel.changeDirection))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundColor(colorForDirection(flashDirection != .none ? flashDirection : viewModel.changeDirection))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.stock.price)
                }
                .padding(.horizontal)

                Text(viewModel.priceText)
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.vertical)

                VStack(alignment: .leading, spacing: 12) {
                    Text("About \(viewModel.symbol)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(viewModel.descriptionText)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
                )
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .background(flashColor.opacity(0.2))
            .onReceive(viewModel.$stock) { stock in
                if let last = lastPrice {
                    if stock.price > last {
                        flashOnce(.green, direction: .up)
                    } else if stock.price < last {
                        flashOnce(.red, direction: .down)
                    }
                }
                lastPrice = stock.price
            }
        }
        .navigationTitle(viewModel.symbol)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func flashOnce(_ color: Color, direction: Stock.ChangeDirection) {
        flashDirection = direction
        withAnimation(.easeOut(duration: 0.12)) { flashColor = color }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.25)) {
                flashColor = .clear
                flashDirection = .none
            }
        }
    }

    private func iconForDirection(_ dir: Stock.ChangeDirection) -> String {
        switch dir {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
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
