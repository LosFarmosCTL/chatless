import TwitchSession

struct ChannelSubscriptionEntry {
  let task: EventSubSubscriptionTask
  var status: EventSubscriptionStatus = .idle
}
