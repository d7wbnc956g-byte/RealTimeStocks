//
//  WebSocketManager.swift
//  RealTimeStocks
//
//  Created by Luke Barkhuizen on 2025/11/26.
//

import Foundation
import Combine

final class WebSocketManager {
    static let shared = WebSocketManager()
    private let url = URL(string: "wss://ws.postman-echo.com/raw")!
    private var task: URLSessionWebSocketTask?
    private var session: URLSession
    private var receiveCancellable: AnyCancellable?
    private let queue = DispatchQueue(label: "websocket.queue")
    private(set) var isConnected = CurrentValueSubject<Bool, Never>(false)

    // publishes raw JSON strings received from socket
    let incoming = PassthroughSubject<String, Never>()

    private init() {
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config)
    }

    func connect() {
        queue.async { [weak self] in
            guard let self = self, self.task == nil else { return }
            self.task = self.session.webSocketTask(with: self.url)
            self.listen()
            self.task?.resume()
            self.isConnected.send(true)
        }
    }

    func disconnect() {
        queue.async { [weak self] in
            guard let self = self, let task = self.task else { return }
            task.cancel(with: .goingAway, reason: nil)
            self.task = nil
            self.isConnected.send(false)
        }
    }

    func send(message: String) {
        queue.async { [weak self] in
            guard let self = self, let task = self.task else { return }
            let wsMessage = URLSessionWebSocketTask.Message.string(message)
            task.send(wsMessage) { error in
                if let error = error {
                    print("WS send error:", error)
                    self.isConnected.send(false)
                }
            }
        }
    }

    private func listen() {
        guard let task = self.task else { return }
        task.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let err):
                print("WebSocket receive error:", err)
                self.isConnected.send(false)
                // try reconnect after short backoff
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    self.connect()
                }
            case .success(let message):
                switch message {
                case .string(let text):
                    self.incoming.send(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.incoming.send(text)
                    }
                @unknown default:
                    break
                }
                // continue listening
                self.listen()
            }
        }
    }
}
