//
//  StockRowView.swift
//  RealTimeStocks
//
//  Created by Luke Barkhuizen on 2025/11/26.
//

import SwiftUI

struct StockRowView: View {
    @ObservedObject var vm: StockViewModel

    var body: some View {
        HStack {
            Text(vm.symbol)
                .font(.headline)
                .frame(minWidth: 70, alignment: .leading)

            Spacer()

            VStack(alignment: .trailing) {
                Text(vm.priceText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(vm.changeText)
                    .font(.caption)
                    .foregroundColor(colorForDirection(vm.changeDirection))
            }

            Image(systemName: iconForDirection(vm.changeDirection))
                .foregroundColor(colorForDirection(vm.changeDirection))
                .padding(.leading, 8)
        }
        .padding(.vertical, 8)
    }

    private func iconForDirection(_ dir: Stock.ChangeDirection) -> String {
        switch dir {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .none: return "minus"
        }
    }

    private func colorForDirection(_ dir: Stock.ChangeDirection) -> Color {
        switch dir {
        case .up: return .green
        case .down: return .red
        case .none: return .secondary
        }
    }
}
