import Foundation

enum BetterTTVProvider {
  private static let globalURL = URL(string: "https://api.betterttv.net/3/cached/emotes/global")!

  static func globalSnapshot() async throws -> ProviderCatalogSnapshot {
    let data = try await ProviderHTTPClient.data(from: globalURL)
    let emotes = try JSONDecoder().decode([Emote].self, from: data)

    return snapshot(emotes: emotes, scope: .global)
  }

  static func channelSnapshot(channelID: String) async throws -> ProviderCatalogSnapshot {
    let url = URL(string: "https://api.betterttv.net/3/cached/users/twitch/\(channelID)")!
    let data = try await ProviderHTTPClient.data(from: url)
    let user = try JSONDecoder().decode(User.self, from: data)

    return snapshot(
      emotes: user.channelEmotes + user.sharedEmotes,
      scope: .channel(channelID)
    )
  }

  private static func snapshot(
    emotes: [Emote],
    scope: EmoteCatalogScope
  ) -> ProviderCatalogSnapshot {
    ProviderCatalogSnapshot(
      key: .init(provider: .betterTTV, scope: scope),
      definitions: emotes.compactMap { emote in
        guard emote.modifier != true else { return nil }

        let variants = [("1x", 28), ("2x", 56), ("3x", 112)].compactMap { scale, size in
          URL(string: "https://cdn.betterttv.net/emote/\(emote.id)/\(scale).webp").map {
            EmoteAssetVariant(
              url: $0,
              pixelWidth: size,
              pixelHeight: size
            )
          }
        }

        return EmoteDefinition(
          id: EmoteID(provider: .betterTTV, value: emote.id),
          name: emote.code,
          variants: variants
        )
      },
      fetchedAt: .now
    )
  }

  private struct Emote: Decodable {
    let id: String
    let code: String
    let modifier: Bool?
  }

  private struct User: Decodable {
    let channelEmotes: [Emote]
    let sharedEmotes: [Emote]
  }
}
