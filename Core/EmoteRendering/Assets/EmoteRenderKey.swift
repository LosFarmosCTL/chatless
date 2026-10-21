import Emotes

struct EmoteRenderKey: Hashable {
  let asset: EmoteAssetKey
  let decodedPixelHeight: Int
}
