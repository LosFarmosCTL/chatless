import Twitch
import TwitchSession

@MainActor
final class ChannelEventSubscriptions {
  var onStatus: (ChannelSubscriptionKey, EventSubscriptionStatus) -> Void = { _, _ in }
  var onStreamOnline: (String) -> Void = { _ in }
  var onStreamOffline: (String) -> Void = { _ in }

  private var context: TwitchClientStore.Context?
  private var subscriptions: [ChannelSubscriptionKey: ChannelSubscriptionEntry] = [:]

  isolated deinit {
    for subscription in subscriptions.values {
      subscription.task.stop()
    }
  }

  func syncChannels(to channelIDs: Set<String>, context: TwitchClientStore.Context?) {
    if self.context?.id != context?.id {
      stop()
      self.context = context
    }

    guard let context else {
      return
    }

    for key in Array(subscriptions.keys) where !channelIDs.contains(key.channelID) {
      stopSubscription(for: key)
    }

    for channelID in channelIDs {
      startSubscription(
        for: ChannelSubscriptionKey(channelID: channelID, kind: .streamOnline),
        context: context
      )
      startSubscription(
        for: ChannelSubscriptionKey(channelID: channelID, kind: .streamOffline),
        context: context
      )
    }
  }

  func retryFailed(in channelID: String, kind: ChannelSubscriptionKind) {
    guard let context else {
      return
    }

    let key = ChannelSubscriptionKey(channelID: channelID, kind: kind)

    guard let subscription = subscriptions[key] else {
      return
    }

    switch subscription.status {
    case .idle, .failed:
      stopSubscription(for: key)
      startSubscription(for: key, context: context)
    case .connecting, .connected, .reconnecting:
      return
    }
  }

  func stop() {
    for key in Array(subscriptions.keys) {
      stopSubscription(for: key)
    }

    context = nil
  }

  private func startSubscription(
    for key: ChannelSubscriptionKey,
    context: TwitchClientStore.Context
  ) {
    guard subscriptions[key] == nil else {
      return
    }

    let task = EventSubSubscriptionTask()
    subscriptions[key] = ChannelSubscriptionEntry(task: task)

    switch key.kind {
    case .streamOnline:
      task.start(
        client: context.client,
        subscription: .streamOnline(broadcasterID: key.channelID),
        onStatus: { [weak self] status in
          self?.updateStatus(status, for: key)
        },
        onEvent: { [weak self] _ in
          self?.onStreamOnline(key.channelID)
        }
      )

    case .streamOffline:
      task.start(
        client: context.client,
        subscription: .streamOffline(broadcasterID: key.channelID),
        onStatus: { [weak self] status in
          self?.updateStatus(status, for: key)
        },
        onEvent: { [weak self] _ in
          self?.onStreamOffline(key.channelID)
        }
      )
    }
  }

  private func updateStatus(_ status: EventSubscriptionStatus, for key: ChannelSubscriptionKey) {
    subscriptions[key]?.status = status
    onStatus(key, status)
  }

  private func stopSubscription(for key: ChannelSubscriptionKey) {
    guard let subscription = subscriptions.removeValue(forKey: key) else {
      return
    }

    subscription.task.stop()

    onStatus(key, .idle)
  }
}
