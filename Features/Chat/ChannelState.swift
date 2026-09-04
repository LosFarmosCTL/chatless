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

  public private(set) var chatMessages: [IncomingChatMessage] = []

  @ObservationIgnored var streamRevision = 0

  @ObservationIgnored private var messageIDs: Set<String> = []

  private let historyLimit = 1_000

  init(channelID: String) {
    self.channelID = channelID
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
    guard message.channelID == channelID,
      messageIDs.insert(message.id).inserted
    else {
      return
    }

    chatMessages.append(message)

    if chatMessages.count > historyLimit {
      let removed = chatMessages.removeFirst()
      messageIDs.remove(removed.id)
    }
  }
}
