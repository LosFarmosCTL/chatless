import Foundation

enum FrankerFaceZProvider {
  private static let globalURL = URL(string: "https://api.frankerfacez.com/v1/set/global")!

  static func globalSnapshot() async throws -> ProviderCatalogSnapshot {
    let data = try await ProviderHTTPClient.data(from: globalURL)
    let response = try JSONDecoder().decode(GlobalResponse.self, from: data)
    let sets = response.defaultSets.compactMap { response.sets[String($0)] }

    return snapshot(sets: sets, scope: .global)
  }

  static func channelSnapshot(channelID: String) async throws -> ProviderCatalogSnapshot {
    let url = URL(string: "https://api.frankerfacez.com/v1/room/id/\(channelID)")!
    let data = try await ProviderHTTPClient.data(from: url)
    let response = try JSONDecoder().decode(RoomResponse.self, from: data)

    return snapshot(sets: Array(response.sets.values), scope: .channel(channelID))
  }

  private static func snapshot(
    sets: [EmoteSet],
    scope: EmoteCatalogScope
  ) -> ProviderCatalogSnapshot {
    let definitions = sets.flatMap(\.emoticons).compactMap { emote -> EmoteDefinition? in
      guard emote.hidden == false, emote.modifier == false else { return nil }

      let images = emote.animated.flatMap { $0.isEmpty ? nil : $0 } ?? emote.urls
      let variants = images.compactMap { scale, value -> EmoteAssetVariant? in
        guard let multiplier = Int(scale),
          let url = URL(string: value.hasPrefix("//") ? "https:" + value : value)
        else { return nil }

        return EmoteAssetVariant(
          url: url,
          pixelWidth: emote.width * multiplier,
          pixelHeight: emote.height * multiplier
        )
      }

      return EmoteDefinition(
        id: EmoteID(provider: .frankerFaceZ, value: String(emote.id)),
        name: emote.name,
        variants: variants
      )
    }

    return ProviderCatalogSnapshot(
      key: .init(provider: .frankerFaceZ, scope: scope),
      definitions: definitions,
      fetchedAt: .now
    )
  }

  private struct GlobalResponse: Decodable {
    let defaultSets: [Int]
    let sets: [String: EmoteSet]

    enum CodingKeys: String, CodingKey {
      case defaultSets = "default_sets"
      case sets
    }
  }

  private struct RoomResponse: Decodable {
    let sets: [String: EmoteSet]
  }

  private struct EmoteSet: Decodable {
    let emoticons: [Emote]
  }

  private struct Emote: Decodable {
    let id: Int
    let name: String
    let height: Int
    let width: Int
    let hidden: Bool
    let modifier: Bool
    let urls: [String: String]
    let animated: [String: String]?
  }
}
