struct ChannelSubscriptionKey: Hashable, Sendable {
  let channelID: String
  let kind: ChannelSubscriptionKind
}
