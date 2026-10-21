import Foundation

public struct EmoteID: Codable, Hashable, Sendable {
  public let provider: EmoteProvider
  public let value: String

  public init(provider: EmoteProvider, value: String) {
    self.provider = provider
    self.value = value
  }
}

public struct EmoteAssetKey: Codable, Hashable, Sendable {
  public let emoteID: EmoteID
  public let variantURL: URL

  public init(emoteID: EmoteID, variantURL: URL) {
    self.emoteID = emoteID
    self.variantURL = variantURL
  }
}
