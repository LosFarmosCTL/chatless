import Foundation

struct EmoteCatalogKey: Hashable, Sendable {
  let provider: EmoteProvider
  let scope: EmoteCatalogScope

  func affects(_ channel: String) -> Bool {
    switch scope {
    case .global: true
    case .channel(let id): id == channel
    }
  }

  func channels(in savedChannels: Set<String>) -> Set<String> {
    switch scope {
    case .global: savedChannels
    case .channel(let id): [id]
    }
  }

  var filename: String {
    let suffix =
      switch scope {
      case .global: "global-global"
      case .channel(let id): "channel-\(id)"
      }

    return "\(provider.rawValue)-\(suffix).json"
  }
}

extension EmoteCatalogKey: Codable {
  private enum CodingKeys: String, CodingKey {
    case provider, channelID
  }

  // Preserve the flat provider/channelID format used by existing disk snapshots.
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    provider = try container.decode(EmoteProvider.self, forKey: .provider)
    scope =
      try container.decodeIfPresent(String.self, forKey: .channelID)
      .map(EmoteCatalogScope.channel) ?? .global
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(provider, forKey: .provider)

    if case .channel(let id) = scope {
      try container.encode(id, forKey: .channelID)
    }
  }
}
