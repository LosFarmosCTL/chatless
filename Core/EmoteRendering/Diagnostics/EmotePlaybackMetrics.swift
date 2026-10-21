import Foundation
import QuartzCore
import os

@MainActor
final class EmotePlaybackMetrics {
  private let diagnostics: EmoteRenderDiagnostics
  private let signpostLog = OSLog(
    subsystem: "app.chatless.Chatless",
    category: "EmoteRendering"
  )
  private var gaugeProvider: (() -> EmoteRenderStatistics)?
  private var diskSizeProvider: ((@escaping (Int) -> Void) -> Void)?
  private var isScrollingProvider: (() -> Bool)?
  private var rawMetrics = EmoteRenderStatistics()
  private var lastTickTimestamp: CFTimeInterval = 0
  private var cadenceWindowStart: CFTimeInterval = 0
  private var cadenceFrameCount = 0
  private var lastMetricsPublication: CFTimeInterval = 0
  private var lastPublishedPresentations = 0
  private var lastPublishedLayoutInvalidations = 0
  private var lastDiskMetricsRefresh: CFTimeInterval = 0
  private var diagnosticsTask: Task<Void, Never>?

  init(diagnostics: EmoteRenderDiagnostics) {
    self.diagnostics = diagnostics
  }

  isolated deinit {
    diagnosticsTask?.cancel()
  }

  func configure(
    gaugeProvider: @escaping () -> EmoteRenderStatistics,
    diskSizeProvider: @escaping (@escaping (Int) -> Void) -> Void,
    isScrollingProvider: @escaping () -> Bool
  ) {
    self.gaugeProvider = gaugeProvider
    self.diskSizeProvider = diskSizeProvider
    self.isScrollingProvider = isScrollingProvider
  }

  func recordTick(timestamp: CFTimeInterval, targetInterval: TimeInterval) {
    if lastTickTimestamp > 0, timestamp - lastTickTimestamp > targetInterval * 1.5 {
      rawMetrics.hitchCount += 1
    }

    lastTickTimestamp = timestamp
    cadenceFrameCount += 1

    if cadenceWindowStart == 0 {
      cadenceWindowStart = timestamp
    }

    let windowDuration = timestamp - cadenceWindowStart

    if windowDuration >= 1 {
      rawMetrics.displayLinkFPS = Double(cadenceFrameCount) / windowDuration
      cadenceFrameCount = 0
      cadenceWindowStart = timestamp
    }
  }

  func resetCadence() {
    rawMetrics.displayLinkFPS = 0
    lastTickTimestamp = 0
    cadenceWindowStart = 0
    cadenceFrameCount = 0
  }

  func recordPresentation() {
    rawMetrics.presentationCount += 1
  }

  func recordLayoutChange() {
    rawMetrics.layoutInvalidationCount += 1
    os_signpost(.event, log: signpostLog, name: "TextLayoutInvalidation")
  }

  func refreshDiskMetricsIfNeeded() {
    guard diagnostics.isEnabled, isScrollingProvider?() == false else { return }

    let now = CACurrentMediaTime()

    guard now - lastDiskMetricsRefresh >= 5 else { return }

    lastDiskMetricsRefresh = now
    refreshDiskMetrics()
  }

  func refreshDiskMetrics() {
    diskSizeProvider? { [weak self] size in
      guard let self else { return }

      self.rawMetrics.encodedDiskBytes = size
      self.publish()
    }
  }

  func setEnabled(_ enabled: Bool) {
    diagnosticsTask?.cancel()
    diagnosticsTask = nil
    resetCadence()

    guard enabled else { return }

    lastMetricsPublication = 0
    lastPublishedPresentations = rawMetrics.presentationCount
    lastPublishedLayoutInvalidations = rawMetrics.layoutInvalidationCount
    diagnosticsTask = Task { @MainActor [weak self] in
      while Task.isCancelled == false {
        guard self != nil else { return }

        self?.publish()
        self?.refreshDiskMetricsIfNeeded()

        do {
          try await Task.sleep(for: .seconds(1))
        } catch {
          return
        }
      }
    }
  }

  private func publish() {
    guard diagnostics.isEnabled, var snapshot = gaugeProvider?() else { return }

    let timestamp = CACurrentMediaTime()

    snapshot.displayLinkFPS = rawMetrics.displayLinkFPS
    snapshot.hitchCount = rawMetrics.hitchCount
    snapshot.presentationCount = rawMetrics.presentationCount
    snapshot.layoutInvalidationCount = rawMetrics.layoutInvalidationCount
    snapshot.encodedDiskBytes = rawMetrics.encodedDiskBytes

    if lastMetricsPublication > 0, timestamp > lastMetricsPublication {
      let interval = timestamp - lastMetricsPublication
      snapshot.presentationsPerSecond =
        Double(rawMetrics.presentationCount - lastPublishedPresentations) / interval
      snapshot.layoutInvalidationsPerSecond =
        Double(rawMetrics.layoutInvalidationCount - lastPublishedLayoutInvalidations) / interval
    }

    lastPublishedPresentations = rawMetrics.presentationCount
    lastPublishedLayoutInvalidations = rawMetrics.layoutInvalidationCount
    lastMetricsPublication = timestamp
    diagnostics.publish(snapshot)
  }
}
