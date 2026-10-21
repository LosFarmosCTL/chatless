import Emotes

struct EmoteAssetSelection: Equatable {
  let key: EmoteRenderKey
  let variant: EmoteAssetVariant

  var requestedPixelHeight: Int { key.decodedPixelHeight }

  init?(definition: EmoteDefinition, pixelHeight: Int, usesHighestScale: Bool = false) {
    let requiredHeight = max(pixelHeight, 1)

    guard
      let variant = usesHighestScale
        ? definition.variants.last
        : definition.variant(forPixelHeight: requiredHeight)
    else { return nil }

    self.variant = variant
    key = EmoteRenderKey(
      asset: EmoteAssetKey(emoteID: definition.id, variantURL: variant.url),
      decodedPixelHeight: usesHighestScale
        ? variant.pixelHeight : min(requiredHeight, variant.pixelHeight)
    )
  }
}
