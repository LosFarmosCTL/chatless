import Foundation

struct SevenTVSubscription: Sendable {
  struct Key: Hashable, Sendable {
    let eventType: String
    let objectID: String
  }

  let key: Key
  let channelIDs: Set<String?>

  static func grouped(_ subscriptions: Set<EmoteLiveSubscription>) -> [Self] {
    let groups = Dictionary(grouping: subscriptions) {
      Key(eventType: $0.eventType, objectID: $0.objectID)
    }

    return groups.map { key, values in
      Self(key: key, channelIDs: Set(values.map(\.channelID)))
    }
  }
}
