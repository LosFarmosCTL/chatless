import Foundation
@preconcurrency import SDWebImage
import UIKit

final class FrameDecodeScheduler: @unchecked Sendable {
  // OperationQueue is thread-safe and is the sole owner of all decoder work.
  private let queue: OperationQueue

  init() {
    queue = OperationQueue()
    queue.name = "Chatless emote frame decoding"
    queue.qualityOfService = .userInitiated
    queue.maxConcurrentOperationCount = 1
  }

  func decode(
    provider: SDAnimatedImage,
    frameIndex: Int,
    completion: @MainActor @escaping (UIImage?) -> Void
  ) {
    queue.addOperation {
      guard OperationQueue.current?.isSuspended == false else { return }

      let frame = provider.animatedImageFrame(at: UInt(frameIndex))
      Task { @MainActor in completion(frame) }
    }
  }

  func cancelAll() {
    queue.cancelAllOperations()
  }
}
