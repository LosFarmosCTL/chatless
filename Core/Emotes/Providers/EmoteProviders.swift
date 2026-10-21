import Foundation

enum EmoteProviders {
  typealias Loader = @Sendable (EmoteCatalogKey) async throws -> ProviderCatalogSnapshot

  // Low to high precedence within each scope.
  static let order: [EmoteProvider] = [.frankerFaceZ, .betterTTV, .sevenTV]

  static func refreshInterval(for provider: EmoteProvider) -> TimeInterval {
    provider == .frankerFaceZ ? 6 * 60 * 60 : 5 * 60
  }

  static func fetch(_ key: EmoteCatalogKey, using load: Loader) async -> ProviderCatalogSnapshot? {
    do {
      return try await load(key)
    } catch ProviderHTTPClient.RequestError.statusCode(404) where key.scope != .global {
      return ProviderCatalogSnapshot(key: key, definitions: [], fetchedAt: .now)
    } catch {
      return nil
    }
  }

  static func load(_ key: EmoteCatalogKey) async throws -> ProviderCatalogSnapshot {
    switch (key.provider, key.scope) {
    case (.frankerFaceZ, .global):
      return try await FrankerFaceZProvider.globalSnapshot()
    case (.frankerFaceZ, .channel(let id)):
      return try await FrankerFaceZProvider.channelSnapshot(channelID: id)
    case (.betterTTV, .global):
      return try await BetterTTVProvider.globalSnapshot()
    case (.betterTTV, .channel(let id)):
      return try await BetterTTVProvider.channelSnapshot(channelID: id)
    case (.sevenTV, .global):
      return try await SevenTVProvider.globalSnapshot()
    case (.sevenTV, .channel(let id)):
      return try await SevenTVProvider.channelSnapshot(channelID: id)
    case (.twitch, _):
      preconditionFailure("Native Twitch emotes are supplied by IRC, not catalogs")
    }
  }
}
