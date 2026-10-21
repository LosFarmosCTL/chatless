import Foundation

enum SevenTVProvider {
  private static let globalURL = URL(string: "https://api.7tv.app/v3/emote-sets/global")!

  static func globalSnapshot() async throws -> ProviderCatalogSnapshot {
    let data = try await ProviderHTTPClient.data(from: globalURL)
    let set = try JSONDecoder().decode(EmoteSet.self, from: data)

    return snapshot(set: set, scope: .global, userID: nil)
  }

  static func channelSnapshot(channelID: String) async throws -> ProviderCatalogSnapshot {
    let url = URL(string: "https://api.7tv.app/v3/users/twitch/\(channelID)")!
    let data = try await ProviderHTTPClient.data(from: url)
    let connection = try JSONDecoder().decode(Connection.self, from: data)

    guard let set = connection.emoteSet else {
      return ProviderCatalogSnapshot(
        key: .init(provider: .sevenTV, scope: .channel(channelID)), definitions: [],
        fetchedAt: .now,
        liveSubscriptions: connection.user.map {
          [
            .init(
              eventType: "user.update", objectID: $0.id, channelID: channelID)
          ]
        } ?? []
      )
    }

    return snapshot(
      set: set,
      scope: .channel(channelID),
      userID: connection.user?.id
    )
  }

  private static func snapshot(
    set: EmoteSet,
    scope: EmoteCatalogScope,
    userID: String?
  ) -> ProviderCatalogSnapshot {
    let definitions = set.emotes.compactMap { entry -> EmoteDefinition? in
      guard let data = entry.data else { return nil }

      let preferredFiles = preferredFiles(from: data.host.files)
      let base = data.host.url.hasPrefix("//") ? "https:\(data.host.url)" : data.host.url
      let variants = preferredFiles.compactMap { file -> EmoteAssetVariant? in
        guard let url = URL(string: "\(base)/\(file.name)") else { return nil }

        return EmoteAssetVariant(
          url: url,
          pixelWidth: file.width,
          pixelHeight: file.height
        )
      }

      return EmoteDefinition(
        id: EmoteID(provider: .sevenTV, value: entry.id),
        name: entry.name,
        variants: variants,
        isZeroWidth: entry.flags & 1 == 1
      )
    }

    return ProviderCatalogSnapshot(
      key: .init(provider: .sevenTV, scope: scope),
      definitions: definitions,
      fetchedAt: .now,
      liveSubscriptions: liveSubscriptions(
        setID: set.id,
        userID: userID,
        scope: scope
      )
    )
  }

  private static func liveSubscriptions(
    setID: String,
    userID: String?,
    scope: EmoteCatalogScope
  ) -> [EmoteLiveSubscription] {
    let channelID: String? =
      switch scope {
      case .global: nil
      case .channel(let id): id
      }

    var subscriptions = [
      EmoteLiveSubscription(
        eventType: "emote_set.update",
        objectID: setID,
        channelID: channelID
      )
    ]

    if let userID {
      subscriptions.append(
        EmoteLiveSubscription(
          eventType: "user.update",
          objectID: userID,
          channelID: channelID
        )
      )
    }

    return subscriptions
  }

  private static func preferredFiles(from files: [HostFile]) -> [HostFile] {
    for format in ["WEBP", "GIF", "PNG", "AVIF"] {
      let matches = files.filter { $0.format.uppercased() == format }

      if matches.isEmpty == false {
        return matches
      }
    }

    return files
  }

  private struct Connection: Decodable {
    let emoteSet: EmoteSet?
    let user: User?

    enum CodingKeys: String, CodingKey {
      case emoteSet = "emote_set"
      case user
    }
  }

  private struct User: Decodable {
    let id: String
  }

  private struct EmoteSet: Decodable {
    let id: String
    let emotes: [EmoteEntry]
  }

  private struct EmoteEntry: Decodable {
    let id: String
    let name: String
    let flags: Int
    let data: EmoteData?
  }

  private struct EmoteData: Decodable {
    let host: Host
  }

  private struct Host: Decodable {
    let url: String
    let files: [HostFile]
  }

  private struct HostFile: Decodable {
    let name: String
    let width: Int
    let height: Int
    let format: String

    enum CodingKeys: String, CodingKey {
      case name, width, height, format
    }
  }
}
