import Foundation

enum EmoteLiveEvent: Sendable {
  case changed(EmoteInvalidationScope)
  case reconnected
}

enum EmoteWebSocketSupport {
  static func data(from message: URLSessionWebSocketTask.Message) -> Data? {
    switch message {
    case .data(let data): data
    case .string(let string): string.data(using: .utf8)
    @unknown default: nil
    }
  }

  static func receive(from socket: URLSessionWebSocketTask) async throws
    -> URLSessionWebSocketTask.Message
  {
    try await withTaskCancellationHandler {
      try Task.checkCancellation()

      return try await socket.receive()
    } onCancel: {
      socket.cancel(with: .goingAway, reason: nil)
    }
  }

  static func reconnectDelay(attempt: Int) -> Duration {
    .seconds(min(1 << min(attempt, 5), 30))
  }
}
