import Foundation

struct SevenTVLiveClient: Sendable {
  private let endpoint = URL(string: "wss://events.7tv.io/v3")!

  func run(
    subscriptions: Set<EmoteLiveSubscription>,
    onEvent: @escaping @Sendable (EmoteLiveEvent) async -> Void
  ) async {
    guard subscriptions.isEmpty == false else { return }

    let subscriptions = SevenTVSubscription.grouped(subscriptions)
    var attempt = 0
    var hasConnected = false

    while !Task.isCancelled {
      do {
        try await connect(subscriptions, onEvent: onEvent) {
          attempt = 0

          if hasConnected {
            await onEvent(.reconnected)
          }

          hasConnected = true
        }
      } catch is CancellationError {
        return
      } catch {
        attempt += 1
        try? await Task.sleep(for: EmoteWebSocketSupport.reconnectDelay(attempt: attempt))
      }
    }
  }

  private func connect(
    _ subscriptions: [SevenTVSubscription],
    onEvent: @escaping @Sendable (EmoteLiveEvent) async -> Void,
    onConnected: () async -> Void
  ) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
      defer { group.cancelAll() }
      var remaining = subscriptions[...]

      while !remaining.isEmpty {
        let connection = try await SevenTVLiveSocket.open(endpoint: endpoint)
        let assigned = Array(remaining.prefix(connection.subscriptionLimit))

        do {
          try await connection.subscribe(assigned)
        } catch {
          connection.close()
          throw error
        }

        remaining = remaining.dropFirst(assigned.count)
        group.addTask {
          try await connection.consume(subscriptions: assigned, onEvent: onEvent)
        }
      }

      await onConnected()
      _ = try await group.next()
      try Task.checkCancellation()
      throw SevenTVLiveSocket.Failure.closed
    }
  }
}
