import Foundation

extension EmotePlaybackCoordinator {
  var statistics: EmoteRenderStatistics {
    var result = EmoteRenderStatistics()
    result.visibleRows = consumers.visibleRowCount
    result.activeEmotes = storage.activeKeys.count
    result.targetPixelHeight = consumers.targetPixelHeight
    result.pendingDownloads = storage.active.count { $0.isLoading }
    result.downloadCount = downloadCount
    result.failureCount = storage.active.count { $0.isFailed }
    result.pendingDecodes = decoder.pendingCount
    result.decodedFrameCount = decoder.decodedFrameCount
    result.droppedFrameRequests = decoder.droppedFrameRequests
    result.cacheHits = cacheHits
    result.cacheMisses = cacheMisses
    result.cacheEvictions = storage.cacheEvictions
    result.decodedBytes = storage.decodedBytes
    result.pinnedDecodedBytes = storage.pinnedDecodedBytes
    result.providerBytes = storage.providerBytes
    result.activeVariantPixelHeights = storage.active.reduce(into: [:]) {
      $0[$1.selection.variant.pixelHeight, default: 0] += 1
    }

    return result
  }

  func recordPresentation(layoutChanged: Bool = false) {
    guard diagnostics.isEnabled else { return }

    metrics.recordPresentation()

    if layoutChanged {
      metrics.recordLayoutChange()
    }
  }

  func configureDiagnostics() {
    metrics.configure(
      gaugeProvider: { [weak self] in self?.statistics ?? EmoteRenderStatistics() },
      diskSizeProvider: { [weak loader] completion in
        loader?.calculateDiskSize(completion: completion)
      },
      isScrollingProvider: { [weak self] in self?.scrollingScopes.isEmpty == false }
    )

    diagnostics.onEnabledChange = { [weak self] enabled in
      self?.metrics.setEnabled(enabled)
      self?.configureTickCollection(enabled: enabled)
    }
  }

  func configureTickCollection(enabled: Bool) {
    if enabled {
      clock.onTick = { [weak self] timestamp, interval in
        self?.metrics.recordTick(timestamp: timestamp, targetInterval: interval)
        self?.advance(at: timestamp)
      }
      clock.onFrameRateChange = { [weak metrics] in metrics?.resetCadence() }
    } else {
      clock.onTick = { [weak self] timestamp, _ in self?.advance(at: timestamp) }
      clock.onFrameRateChange = nil
    }
  }
}
