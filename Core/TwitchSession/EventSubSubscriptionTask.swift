import Foundation
import Twitch

@MainActor
public final class EventSubSubscriptionTask {
  private var task: Task<Void, Never>?
  private var hasStarted = false

  public init() {}

  deinit { task?.cancel() }

  public func start<Event: Decodable & Sendable>(
    client: TwitchClient,
    subscription: EventSubSubscription<Event>,
    onStatus: @escaping @MainActor (EventSubscriptionStatus) -> Void,
    onEvent: @escaping @MainActor (Event) -> Void
  ) {
    guard !hasStarted else { return }

    hasStarted = true

    task = Task {
      await Self.consumeWithRetry(
        client: client,
        subscription: subscription,
        onStatus: onStatus,
        onEvent: onEvent
      )
    }

    onStatus(.connecting)
  }

  private static func consumeWithRetry<Event: Decodable & Sendable>(
    client: TwitchClient,
    subscription: EventSubSubscription<Event>,
    onStatus: @MainActor (EventSubscriptionStatus) -> Void,
    onEvent: @MainActor (Event) -> Void
  ) async {
    var attempt = 0
    var conflictFailures = 0

    while !Task.isCancelled {
      do {
        try await Self.consume(
          client: client,
          subscription: subscription,
          onStatus: { status in
            attempt = 0
            conflictFailures = 0

            onStatus(status)
          },
          onEvent: onEvent
        )

        guard !Task.isCancelled else { return }

        onStatus(.idle)
        return
      } catch {
        guard !Task.isCancelled else { return }
        if error is CancellationError { return }

        let message = String(describing: error)

        if case .twitchError(_, 409, _) = error as? HelixError { conflictFailures += 1 }

        if Self.shouldRetry(error, conflictFailures: conflictFailures) {
          onStatus(.reconnecting(message))
        } else {
          onStatus(.failed(message))
          return
        }
      }

      guard await Self.waitToRetry(attempt: attempt) else { return }

      attempt += 1
    }
  }

  private static func waitToRetry(attempt: Int) async -> Bool {
    let delay = Double(min(1 << min(attempt, 5), 30))

    do {
      try await Task.sleep(for: .seconds(delay + Double.random(in: 0...0.5)))

      return true
    } catch {
      return false
    }
  }

  public func stop() {
    task?.cancel()
    task = nil
  }

  private static func consume<Event: Decodable & Sendable>(
    client: TwitchClient,
    subscription: EventSubSubscription<Event>,
    onStatus: @MainActor (EventSubscriptionStatus) -> Void,
    onEvent: @MainActor (Event) -> Void
  ) async throws {
    let stream = try await client.eventStream(for: subscription)

    if !Task.isCancelled { onStatus(.connected) }

    for try await event in stream {
      guard !Task.isCancelled else { return }

      onEvent(event)
    }
  }

  private static func shouldRetry(
    _ error: Error,
    conflictFailures: Int
  ) -> Bool {
    if let error = error as? EventSubError {
      switch error {
      case .disconnected, .timedOut: return true
      case .revocation: return false
      }
    }

    if let error = error as? HelixError {
      switch error {
      case .networkError: return true
      case .twitchError(_, let status, _):
        if status == 409 {
          // A previous subscription may still be deleting. Retry briefly,
          // then surface persistent duplicates instead of retrying indefinitely.
          return conflictFailures <= 3
        }

        return status == 429 || status >= 500
      default: return false
      }
    }

    return false
  }
}
