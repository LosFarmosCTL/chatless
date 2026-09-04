import Foundation
import Observation
import TwitchSession

@MainActor
@Observable public final class ChannelStore {
  private var channels: [String: ChannelState] = [:]

  @ObservationIgnored private var logins: [String: String] = [:]
  @ObservationIgnored private var channelIDsByLogin: [String: String] = [:]

  @ObservationIgnored private(set) var context: TwitchClientStore.Context?
  @ObservationIgnored private let chat = IRCChatConnection()
  @ObservationIgnored private let events = ChannelEventSubscriptions()

  // Stream reconciliation is implemented in ChannelStore+StreamStatus.
  @ObservationIgnored var refreshTokens: [String: UUID] = [:]
  @ObservationIgnored var refreshTask: Task<Void, Never>?
  @ObservationIgnored var pendingRefreshes:
    [String: (state: ChannelState, revision: Int, titleOnly: Bool)] = [:]

  var savedChannelIDs: Set<String> {
    Set(logins.keys)
  }

  public init() {
    chat.onMessage = { [weak self] message in
      guard let self, let id = channelIDsByLogin[message.channel.lowercased()] else {
        return
      }

      channels[id]?.receive(IncomingChatMessage(message: message, channelID: id))
    }

    chat.onStatus = { [weak self] login, status in
      guard let self, let id = channelIDsByLogin[login] else {
        return
      }

      channels[id]?.connectionStatus = status
    }

    events.onStatus = { [weak self] key, status in
      self?.receiveSubscriptionStatus(status, for: key)
    }

    events.onStreamOnline = { [weak self] channelID in
      self?.receiveStreamOnline(in: channelID)
    }

    events.onStreamOffline = { [weak self] channelID in
      self?.receiveStreamOffline(in: channelID)
    }
  }

  isolated deinit {
    events.stop()
    refreshTask?.cancel()
  }

  public func state(for id: String) -> ChannelState? {
    channels[id]
  }

  @discardableResult
  public func channel(for id: String) -> ChannelState {
    if let existing = channels[id] {
      return existing
    }

    let state = ChannelState(channelID: id)
    channels[id] = state

    return state
  }

  public func syncChannels(to channelLogins: [String: String]) {
    let ids = Set(channelLogins.keys)
    let addedIDs = ids.subtracting(savedChannelIDs)

    for id in Set(channels.keys).subtracting(ids) {
      refreshTokens[id] = nil
      pendingRefreshes[id] = nil

      if let state = channels.removeValue(forKey: id) {
        state.connectionStatus = .idle
        state.resetSubscriptionStatuses()
      }
    }

    logins = channelLogins.mapValues { $0.lowercased() }
    channelIDsByLogin = Dictionary(
      logins.map { ($0.value, $0.key) },
      uniquingKeysWith: { first, _ in first }
    )

    for id in ids {
      channel(for: id)
    }

    chat.setChannels(Set(logins.values))
    events.syncChannels(to: ids, context: context)

    for id in addedIDs {
      scheduleRefresh(for: id)
    }
  }

  public func apply(context: TwitchClientStore.Context?) {
    guard self.context?.id != context?.id else {
      return
    }

    refreshTask?.cancel()
    refreshTask = nil
    pendingRefreshes.removeAll()
    refreshTokens.removeAll()

    self.context = context

    // anonymous chat and its history are independent of authenticated EventSub/Helix.
    for state in channels.values {
      state.resetSubscriptionStatuses()
    }

    events.syncChannels(to: savedChannelIDs, context: context)

    for id in savedChannelIDs {
      scheduleRefresh(for: id)
    }
  }

  public func retryMessages(in channelID: String) {
    if let login = logins[channelID] {
      chat.retry(login)
    }
  }

  public func retrySubscription(_ kind: ChannelSubscriptionKind, in channelID: String) {
    events.retryFailed(in: channelID, kind: kind)
  }

  public func retryStreamEvents(in channelID: String) {
    retrySubscription(.streamOnline, in: channelID)
    retrySubscription(.streamOffline, in: channelID)
  }
}
