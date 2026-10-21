import Foundation
import QuartzCore

extension EmotePlaybackCoordinator {
  func ensurePrepared(_ record: EmoteAssetRecord) {
    guard policy.isSceneActive else { return }

    if record.timeline != nil {
      updateFrame(for: record, elapsed: CACurrentMediaTime() - epoch)

      return
    }

    load(record)
  }

  func load(_ record: EmoteAssetRecord) {
    record.load(using: loader) { [weak self, weak record] outcome in
      guard let self, let record, storage.record(for: record.selection.key) === record else {
        return
      }

      switch outcome {
      case .loaded(let asset):
        if asset.cameFromNetwork {
          downloadCount += 1
        }

        storage.install(asset.image, encodedData: asset.encodedData, asset: record.selection.key)
        ensurePrepared(record)
        updateClock()
      case .failed:
        record.state = .failed
      }
    }
  }

  public func retryFailures() {
    loader.retryFailures()

    for record in storage.active where record.isFailed {
      record.state = .loading(aspectRatio: record.aspectRatio)
      ensurePrepared(record)
    }
  }

  public func clearDisk() {
    loader.clearDisk { [weak self] in
      guard let self, diagnostics.isEnabled else { return }

      metrics.refreshDiskMetrics()
    }
  }
}
