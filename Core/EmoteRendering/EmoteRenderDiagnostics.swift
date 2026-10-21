import Foundation
import Observation

public struct EmoteRenderStatistics: Equatable, Sendable {
  public var displayLinkFPS: Double = 0
  public var hitchCount = 0
  public var visibleRows = 0
  public var activeEmotes = 0
  public var pendingDownloads = 0
  public var pendingDecodes = 0
  public var downloadCount = 0
  public var decodedFrameCount = 0
  public var droppedFrameRequests = 0
  public var cacheHits = 0
  public var cacheMisses = 0
  public var cacheHitRate: Double {
    let requests = cacheHits + cacheMisses

    return requests == 0 ? 0 : Double(cacheHits) / Double(requests)
  }

  public var cacheEvictions = 0
  public var decodedBytes = 0
  public var pinnedDecodedBytes = 0
  public var providerBytes = 0
  public var encodedDiskBytes = 0
  public var failureCount = 0
  public var presentationCount = 0
  public var layoutInvalidationCount = 0
  public var presentationsPerSecond: Double = 0
  public var layoutInvalidationsPerSecond: Double = 0
  public var targetPixelHeight = 0
  public var activeVariantPixelHeights: [Int: Int] = [:]

  public init() {}
}

@MainActor
@Observable public final class EmoteRenderDiagnostics {
  @ObservationIgnored var onEnabledChange: ((Bool) -> Void)?

  public var isEnabled = false {
    didSet {
      if isEnabled == false {
        latestSnapshot = EmoteRenderStatistics()
      }

      onEnabledChange?(isEnabled)
    }
  }

  public private(set) var latestSnapshot = EmoteRenderStatistics()

  public init() {}

  func publish(_ snapshot: EmoteRenderStatistics) {
    guard isEnabled else { return }

    latestSnapshot = snapshot
  }
}
