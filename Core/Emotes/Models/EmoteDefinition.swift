import Foundation

public struct EmoteDefinition: Codable, Hashable, Identifiable, Sendable {
  public let id: EmoteID
  public let name: String
  public let variants: [EmoteAssetVariant]
  public let isZeroWidth: Bool

  public init(
    id: EmoteID,
    name: String,
    variants: [EmoteAssetVariant],
    isZeroWidth: Bool = false
  ) {
    self.id = id
    self.name = name
    self.variants = variants.sorted {
      if $0.pixelHeight == $1.pixelHeight {
        return $0.pixelWidth < $1.pixelWidth
      }

      return $0.pixelHeight < $1.pixelHeight
    }

    self.isZeroWidth = isZeroWidth
  }

  public func variant(forPixelHeight requiredPixelHeight: Int) -> EmoteAssetVariant? {
    variants.first { $0.pixelHeight >= requiredPixelHeight } ?? variants.last
  }
}
