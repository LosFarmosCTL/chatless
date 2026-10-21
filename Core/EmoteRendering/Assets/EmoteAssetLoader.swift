import Emotes
import Foundation
@preconcurrency import SDWebImage
import UIKit

@MainActor
final class EmoteAssetLoader {
  struct LoadedAsset {
    let image: UIImage
    let encodedData: Data?
    let cameFromNetwork: Bool
  }

  enum Outcome {
    case loaded(LoadedAsset)
    case failed
  }

  private struct CallbackResult {
    let image: UIImage?
    let data: Data?
    let error: Error?
    let cacheType: SDImageCacheType
  }

  private let imageCache: SDImageCache
  private let imageManager: SDWebImageManager

  init() {
    let config = SDImageCacheConfig()
    config.shouldCacheImagesInMemory = false
    config.shouldUseWeakMemoryCache = false
    config.maxDiskAge = -1
    config.maxDiskSize = 256 * 1_024 * 1_024
    config.diskCacheExpireType = .accessDate
    imageCache = SDImageCache(
      namespace: "ChatlessEmotes",
      diskCacheDirectory: nil,
      config: config
    )

    let downloaderConfig = SDWebImageDownloaderConfig()
    downloaderConfig.maxConcurrentDownloads = 6
    let downloader = SDWebImageDownloader(config: downloaderConfig)
    imageManager = SDWebImageManager(cache: imageCache, loader: downloader)

    SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)
  }

  // Completion always hops to the main actor before the caller's request can finish.
  func load(
    _ selection: EmoteAssetSelection,
    completion: @escaping (Outcome) -> Void
  ) -> SDWebImageCombinedOperation? {
    let pixelHeight = CGFloat(selection.requestedPixelHeight)
    let context: [SDWebImageContextOption: Any] = [
      .animatedImageClass: SDAnimatedImage.self,
      .imageThumbnailPixelSize: NSValue(
        cgSize: CGSize(width: pixelHeight * 4, height: pixelHeight)),
      .queryCacheType: SDImageCacheType.disk.rawValue,
      .storeCacheType: SDImageCacheType.disk.rawValue,
    ]

    return imageManager.loadImage(
      with: selection.variant.url,
      options: [.retryFailed],
      context: context,
      progress: nil
    ) { image, data, error, cacheType, finished, _ in
      guard finished else { return }

      let result = CallbackResult(image: image, data: data, error: error, cacheType: cacheType)

      Task { @MainActor in
        guard result.error == nil, let image = result.image else {
          completion(.failed)

          return
        }

        completion(
          .loaded(
            LoadedAsset(
              image: image, encodedData: result.data, cameFromNetwork: result.cacheType == .none)))
      }
    }
  }

  func retryFailures() {
    imageManager.removeAllFailedURLs()
  }

  func clearDisk(completion: @escaping () -> Void) {
    imageCache.clearDisk {
      Task { @MainActor in completion() }
    }
  }

  func calculateDiskSize(completion: @escaping (Int) -> Void) {
    imageCache.calculateSize { _, size in
      Task { @MainActor in completion(Int(size)) }
    }
  }
}
