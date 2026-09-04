import TwitchSession

extension ChannelStore {
  func receiveSubscriptionStatus(
    _ status: EventSubscriptionStatus,
    for key: ChannelSubscriptionKey
  ) {
    guard let state = state(for: key.channelID) else { return }

    state.setSubscriptionStatus(status, for: key.kind)

    switch key.kind {
    case .streamOnline, .streamOffline:
      if status == .connected {
        scheduleRefresh(for: key.channelID)
      }
    }
  }

  func receiveStreamOnline(in channelID: String) {
    guard let state = state(for: channelID) else { return }

    state.streamRevision += 1
    state.isLive = true
    state.streamTitle = ""

    scheduleRefresh(for: channelID, titleOnly: true)
  }

  func receiveStreamOffline(in channelID: String) {
    guard let state = state(for: channelID) else {
      return
    }

    state.streamRevision += 1
    state.isLive = false
    state.streamTitle = ""
  }
}
