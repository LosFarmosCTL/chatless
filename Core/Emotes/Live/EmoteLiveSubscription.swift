import Foundation

struct EmoteLiveSubscription: Codable, Hashable, Sendable {
  let eventType: String
  let objectID: String
  let channelID: String?
}
