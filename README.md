Real-Time Stock Price Tracker

A SwiftUI iOS application that displays real-time price updates for multiple stock symbols, with detailed views per symbol. The project demonstrates MVVM architecture, Combine-based reactive programming, and unit testing.

⸻

Features

Live Stock Feed
	•	Displays a list of 25 stock symbols (e.g., AAPL, GOOG, TSLA, AMZN, MSFT, NVDA).
	•	Real-time price updates simulated via a WebSocket-like flow.
	•	Each stock row shows:
	•	Symbol
	•	Current price
	•	Price change indicator (↑ for increase, ↓ for decrease)
	•	List sorted by highest price first.

Feed Controls
	•	Connection status indicator (🟢 connected / 🔴 disconnected).
	•	Start/Stop feed button to simulate live updates.

Detail View
	•	Displays:
	•	Symbol name as the title
	•	Current price with change indicator
	•	Stock description

Unit Testing
	•	StockViewModel fully unit-tested:
	•	Price increase
	•	Price decrease
	•	No change
	•	Tests simulate feed updates using a mock feed provider.
	•	Ensures changeText, priceText, and changeDirection are correct.

Architecture
	•	MVVM pattern:
	•	FeedViewModel: manages stock feed, simulates price updates.
	•	StockViewModel: observes feed and exposes stock details for UI.
	•	FeedView and DetailView: SwiftUI views for listing stocks and showing details.
	•	Combine used for reactive binding between feed and view models.
	•	Fully SwiftUI-based UI with immutable state updates.

⸻

Installation & Setup
1.	Clone the repository:
   
  git clone [https://github.com/yourusername/RealTimeStocks.git](https://github.com/d7wbnc956g-byte/RealTimeStocks.git)
cd RealTimeStocks

3.	Open the project in Xcode (≥ 15.0):
   
  open RealTimeStocks.xcodeproj

5.	Build and run on the simulator or a physical device.

⸻

Usage
	•	Launch the app → see the stock list.
	•	Tap Start Feed to begin price updates.
	•	Tap any stock row → navigate to DetailView.
	•	Observe price change indicators updating in real time.

⸻
Folder Structure:

RealTimeStocks/
├── Models/
│   └── Stock.swift
├── ViewModels/
│   ├── FeedViewModel.swift
│   └── StockViewModel.swift
├── Views/
│   ├── FeedView.swift
│   └── DetailView.swift
├── Price Formatter/
│   └── PriceFormatter.swift
└── RealTimeStocks.xcodeproj
