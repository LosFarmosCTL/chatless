import Emotes
import Observation
import TwitchSession

@MainActor
@Observable public final class ChannelState {
  public let channelID: String

  public internal(set) var connectionStatus: ChatConnectionStatus = .idle
  public private(set) var subscriptionStatuses: [ChannelSubscriptionKind: EventSubscriptionStatus] =
    [:]

  public internal(set) var isLive = false
  public internal(set) var streamTitle = ""

  let feed: ChatFeedStore

  @ObservationIgnored var streamRevision = 0

  init(channelID: String) {
    self.channelID = channelID
    self.feed = ChatFeedStore(channelID: channelID)
  }

  public func subscriptionStatus(for kind: ChannelSubscriptionKind) -> EventSubscriptionStatus {
    subscriptionStatuses[kind] ?? .idle
  }

  func setSubscriptionStatus(_ status: EventSubscriptionStatus, for kind: ChannelSubscriptionKind) {
    subscriptionStatuses[kind] = status == .idle ? nil : status
  }

  func resetSubscriptionStatuses() {
    subscriptionStatuses.removeAll()
  }

  func receive(_ message: IncomingChatMessage) {
    feed.receive(message)
  }

  func apply(_ update: EmoteCatalogUpdate) {
    feed.apply(update)
  }
}
