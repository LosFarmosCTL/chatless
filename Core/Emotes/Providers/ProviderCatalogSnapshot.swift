import Foundation

struct ProviderCatalogSnapshot: Codable, Sendable {
  let key: EmoteCatalogKey
  let definitions: [EmoteDefinition]
  let fetchedAt: Date
  let liveSubscriptions: [EmoteLiveSubscription]

  init(
    key: EmoteCatalogKey,
    definitions: [EmoteDefinition],
    fetchedAt: Date,
    liveSubscriptions: [EmoteLiveSubscription] = []
  ) {
    self.key = key
    self.definitions = definitions
    self.fetchedAt = fetchedAt
    self.liveSubscriptions = liveSubscriptions
  }

  // Keep the flat provider/channelID representation compatible with existing disk snapshots.
  init(from decoder: Decoder) throws {
    key = try EmoteCatalogKey(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    definitions = try container.decode([EmoteDefinition].self, forKey: .definitions)
    fetchedAt = try container.decode(Date.self, forKey: .fetchedAt)
    liveSubscriptions =
      try container.decodeIfPresent([EmoteLiveSubscription].self, forKey: .liveSubscriptions) ?? []
  }

  func encode(to encoder: Encoder) throws {
    try key.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(definitions, forKey: .definitions)
    try container.encode(fetchedAt, forKey: .fetchedAt)
    try container.encode(liveSubscriptions, forKey: .liveSubscriptions)
  }

  private enum CodingKeys: String, CodingKey {
    case definitions, fetchedAt, liveSubscriptions
  }
}
