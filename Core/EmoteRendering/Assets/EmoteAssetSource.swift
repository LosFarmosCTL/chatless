@preconcurrency import SDWebImage
import UIKit

struct EmoteAssetSource {
  let provider: SDAnimatedImage?
  let timeline: FrameTimeline
  let aspectRatio: CGFloat
  let cost: Int

  init(image: UIImage, encodedData: Data?) {
    aspectRatio =
      image.size.height > 0
      ? max(image.size.width / image.size.height, 0.25) : 1

    if let animated = image as? SDAnimatedImage, animated.animatedImageFrameCount > 1 {
      provider = animated
      timeline = FrameTimeline(
        durations: (0..<animated.animatedImageFrameCount).map {
          animated.animatedImageDuration(at: $0)
        })
      cost = encodedData?.count ?? animated.animatedImageData?.count ?? 1
    } else {
      provider = nil
      timeline = FrameTimeline(durations: [1])
      cost = 0
    }
  }
}
