//
//  MockWebSocketManager.swift
//  RealTimeStocks
//
//  Created by Luke Barkhuizen on 2025/11/26.
//

import Foundation
import Combine
@testable import RealTimeStocks

final class MockWebSocketManager: WebSocketManagerType {
    var isConnected = CurrentValueSubject<Bool, Never>(false)
    var incoming = PassthroughSubject<String, Never>()
    var sentMessages: [String] = []

    func connect() { isConnected.send(true) }
    func disconnect() { isConnected.send(false) }
    func send(message: String) {
        sentMessages.append(message)
    }
}
