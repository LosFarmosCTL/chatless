import Foundation
import SwiftUI

@MainActor
extension EnvironmentValues {
  @Entry public var channelEventRegistry: ChannelEventStateRegistry?
}

@MainActor
public final class ChannelEventStateRegistry {
  private var states: [String: ChannelEventState] = [:]
  private var currentSession: TwitchSessionStore.Session?

  public init() {}

  @discardableResult
  public func getOrCreateChannel(_ id: String) -> ChannelEventState {
    if let existing = states[id] { return existing }

    let state = ChannelEventState(channelID: id)
    states[id] = state

    if let session = currentSession {
      state.start(session: session)
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

  public func apply(session: TwitchSessionStore.Session?) {
    currentSession = session
    states.values.forEach { $0.stop() }

    guard let session else { return }
    states.values.forEach { $0.start(session: session) }
  }
}
