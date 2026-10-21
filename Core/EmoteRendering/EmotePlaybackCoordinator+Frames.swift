import Foundation
import QuartzCore
import os

extension EmotePlaybackCoordinator {
  func advance(at timestamp: CFTimeInterval) {
    guard policy.allowsAnimation else { return }

    let elapsed = timestamp - epoch

    for record in storage.active where record.isAnimated {
      updateFrame(for: record, elapsed: elapsed)
    }
  }

  func updateFrame(for record: EmoteAssetRecord, elapsed: TimeInterval) {
    guard let timeline = record.timeline else { return }

    let asset = record.selection.key
    let target = policy.animatedEmotesEnabled ? timeline.frameIndex(at: elapsed) : 0
    // A late decode must not overwrite a newly selected poster or cached frame.
    record.requestedFrameIndex = target

    if record.currentFrameIndex == target, record.currentImage != nil {
      decoder.discardQueued(for: asset)
      return
    }

    let key = FrameKey(asset: asset, index: target)

    if let cached = storage.takeFrame(for: key) {
      decoder.discardQueued(for: asset)
      cacheHits += 1
      os_signpost(.event, log: signpostLog, name: "FrameCacheHit")
      storage.replaceCurrentFrame(cached, asset: asset, index: target)

      return
    }

    guard let provider = record.source?.provider else {
      load(record)

      return
    }

    let result = decoder.request(key: key, provider: provider) { [weak self, weak record] frame in
      guard let self, let record, let frame, storage.record(for: asset) === record else { return }

      if record.requestedFrameIndex == target {
        storage.replaceCurrentFrame(frame, asset: asset, index: target)
      } else {
        storage.cacheFrame(frame, for: key)
      }
    }

    if case .scheduled = result {
      cacheMisses += 1
    }
  }
}
