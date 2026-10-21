import Foundation

@MainActor
final class EmoteLiveConnectionCoordinator {
  typealias InvalidationHandler = @MainActor @Sendable (EmoteProvider, EmoteLiveEvent) -> Void

  private var betterTTV: Task<Void, Never>?
  private var sevenTV: Task<Void, Never>?

  isolated deinit {
    betterTTV?.cancel()
    sevenTV?.cancel()
  }

  func restartAll(
    channels: Set<String>, subscriptions: Set<EmoteLiveSubscription>,
    onInvalidation: @escaping InvalidationHandler
  ) {
    stop()
    betterTTV = Task {
      await BetterTTVLiveClient().run(channels: channels) { event in
        await Self.deliver(event, provider: .betterTTV, to: onInvalidation)
      }
    }
    restartSevenTV(subscriptions: subscriptions, onInvalidation: onInvalidation)
  }

  func restartSevenTV(
    subscriptions: Set<EmoteLiveSubscription>, onInvalidation: @escaping InvalidationHandler
  ) {
    sevenTV?.cancel()
    sevenTV = nil
    guard !subscriptions.isEmpty else { return }

    sevenTV = Task {
      await SevenTVLiveClient().run(subscriptions: subscriptions) { event in
        await Self.deliver(event, provider: .sevenTV, to: onInvalidation)
      }
    }
  }

  func stop() {
    betterTTV?.cancel()
    sevenTV?.cancel()
    betterTTV = nil
    sevenTV = nil
  }

  private static func deliver(
    _ event: EmoteLiveEvent, provider: EmoteProvider, to handler: InvalidationHandler
  ) {
    guard !Task.isCancelled else { return }

    handler(provider, event)
  }
}
