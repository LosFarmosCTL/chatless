import Foundation
import QuartzCore
import UIKit

@MainActor
final class DisplayLinkDriver {
  private var displayLink: CADisplayLink?
  private let target = DisplayLinkTarget()
  private var powerStateObserver: NotificationCenter.ObservationToken?
  private var isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled

  var onTick: ((CFTimeInterval, TimeInterval) -> Void)?
  var onFrameRateChange: (() -> Void)?

  init() {
    target.driver = self
    powerStateObserver = NotificationCenter.default.addObserver(
      of: ProcessInfo.processInfo,
      for: .powerStateDidChange
    ) { [weak self] _ in
      await self?.powerStateDidChange()
    }
  }

  func setRunning(_ shouldRun: Bool) {
    if shouldRun {
      if displayLink == nil {
        let link = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
      }

      displayLink?.preferredFrameRateRange = preferredFrameRateRange
      displayLink?.isPaused = false
    } else {
      displayLink?.isPaused = true
    }
  }

  isolated deinit {
    displayLink?.invalidate()
  }

  func displayLinkDidFire(_ link: CADisplayLink) {
    let framesPerSecond = isLowPowerModeEnabled ? 30 : 60
    let targetInterval = max(
      link.targetTimestamp - link.timestamp,
      1 / Double(framesPerSecond)
    )

    onTick?(link.timestamp, targetInterval)
  }

  private func powerStateDidChange() {
    isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
    displayLink?.preferredFrameRateRange = preferredFrameRateRange
    onFrameRateChange?()
  }

  private var preferredFrameRateRange: CAFrameRateRange {
    let fps: Float = isLowPowerModeEnabled ? 30 : 60

    return CAFrameRateRange(minimum: fps, maximum: fps, preferred: fps)
  }
}
