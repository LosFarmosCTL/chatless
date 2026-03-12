import Foundation
import SwiftUI

@MainActor
@Observable public final class ChannelEventStateRegistry {
  private var states: [String: ChannelEventState] = [:]
  private var currentContext: TwitchClientStore.Context?

  public init() {}

  @discardableResult
  public func getOrCreateChannel(_ id: String) -> ChannelEventState {
    if let existing = states[id] { return existing }

    let state = ChannelEventState(channelID: id)
    states[id] = state

    if let context = currentContext {
      state.start(context: context)
    }

    return state
  }

  public func removeChannel(_ id: String) {
    guard let state = states[id] else { return }
    state.stop()
    states.removeValue(forKey: id)
  }

  public func syncChannels(to channelIDs: Set<String>) {
    let current = Set(states.keys)

    for channelID in current.subtracting(channelIDs) { removeChannel(channelID) }
    for channelID in channelIDs.subtracting(current) { getOrCreateChannel(channelID) }
  }

  public func apply(context: TwitchClientStore.Context?) {
    currentContext = context
    states.values.forEach { $0.stop() }

    guard let context else { return }
    states.values.forEach { $0.start(context: context) }
  }
}
