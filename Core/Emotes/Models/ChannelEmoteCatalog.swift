import Foundation

public struct ChannelEmoteCatalog: Codable, Equatable, Sendable {
  public let channelID: String
  public let definitionsByName: [String: EmoteDefinition]
  public let revision: UInt64
  public let isReady: Bool
  public let unavailableProviders: Set<EmoteProvider>

  public var isComplete: Bool { isReady && unavailableProviders.isEmpty }

  public init(
    channelID: String,
    definitionsByName: [String: EmoteDefinition] = [:],
    revision: UInt64 = 0,
    isReady: Bool = false,
    unavailableProviders: Set<EmoteProvider> = []
  ) {
    self.channelID = channelID
    self.definitionsByName = definitionsByName
    self.revision = revision
    self.isReady = isReady
    self.unavailableProviders = unavailableProviders
  }

  public func definition(named name: String) -> EmoteDefinition? {
    definitionsByName[name]
  }
}

public enum EmoteCatalogUpdateReason: String, Sendable {
  case initial
  case live
  case reconciliation
}

public struct EmoteCatalogUpdate: Sendable {
  public let catalog: ChannelEmoteCatalog
  public let reason: EmoteCatalogUpdateReason

  public init(catalog: ChannelEmoteCatalog, reason: EmoteCatalogUpdateReason) {
    self.catalog = catalog
    self.reason = reason
  }
}
