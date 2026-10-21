import Foundation

public struct EmoteAssetVariant: Codable, Hashable, Identifiable, Sendable {
  public let url: URL
  public let pixelWidth: Int
  public let pixelHeight: Int

  public var id: URL { url }

  public init(
    url: URL,
    pixelWidth: Int,
    pixelHeight: Int
  ) {
    self.url = url
    self.pixelWidth = max(pixelWidth, 1)
    self.pixelHeight = max(pixelHeight, 1)
  }
}
