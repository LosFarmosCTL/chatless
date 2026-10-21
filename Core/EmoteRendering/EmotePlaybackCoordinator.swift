import Emotes
import Foundation
import Observation
import QuartzCore
import UIKit
import os

@MainActor
@Observable public final class EmotePlaybackCoordinator: NSObject {
  public let diagnostics: EmoteRenderDiagnostics

  @ObservationIgnored let consumers = EmoteConsumerRegistry()
  @ObservationIgnored let loader = EmoteAssetLoader()
  @ObservationIgnored let decoder = EmoteFrameDecoder()
  @ObservationIgnored let storage = EmoteFrameStorage()
  @ObservationIgnored let clock = DisplayLinkDriver()
  @ObservationIgnored let metrics: EmotePlaybackMetrics
  @ObservationIgnored var policy = EmotePlaybackPolicy()
  @ObservationIgnored var scrollingScopes: Set<UUID> = []
  @ObservationIgnored var downloadCount = 0
  @ObservationIgnored var cacheHits = 0
  @ObservationIgnored var cacheMisses = 0

  let epoch = CACurrentMediaTime()
  let signpostLog = OSLog(subsystem: "app.chatless.Chatless", category: "EmoteRendering")

  public override init() {
    let diagnostics = EmoteRenderDiagnostics()
    self.diagnostics = diagnostics
    metrics = EmotePlaybackMetrics(diagnostics: diagnostics)
    super.init()

    consumers.onDemandChange = { [weak self] in self?.applyDemand($0) }
    configureDiagnostics()
    configureTickCollection(enabled: false)
    NotificationCenter.default.addObserver(
      self, selector: #selector(didReceiveMemoryWarning),
      name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
  }

  isolated deinit {
    decoder.cancelAll()

    for key in storage.activeKeys {
      storage.deactivate(key)
    }
  }

  func asset(for selection: EmoteAssetSelection) -> EmoteAssetRecord {
    storage.asset(for: selection)
  }

  private func applyDemand(_ assets: [EmoteRenderKey: EmoteAssetRecord]) {
    for key in storage.activeKeys.subtracting(assets.keys) {
      decoder.cancel(key)
      storage.deactivate(key)
    }

    for (key, record) in assets where storage.record(for: key) == nil {
      storage.activate(record)
      ensurePrepared(record)
    }

    storage.pruneReferences()
    updateClock()
  }

  public func clearVisibleMessages(scope: UUID) {
    consumers.clear(scope: scope)
    scrollingScopes.remove(scope)
  }

  public func setScrolling(_ scrolling: Bool, scope: UUID) {
    if scrolling {
      scrollingScopes.insert(scope)
    } else if scrollingScopes.remove(scope) != nil {
      refreshActiveEmotes()
    }
  }

  public func setSceneActive(_ active: Bool) {
    guard policy.isSceneActive != active else { return }

    policy.isSceneActive = active

    if active {
      refreshActiveEmotes()
    } else {
      decoder.cancelAll()
    }

    updateClock()
  }

  public func setAnimatedEmotesEnabled(_ enabled: Bool) {
    guard policy.animatedEmotesEnabled != enabled else { return }

    policy.animatedEmotesEnabled = enabled
    refreshActiveEmotes()
    updateClock()
  }

  public func clearMemory() {
    decoder.cancelAll()
    storage.clearAll()
    refreshActiveEmotes()
    updateClock()
  }

  func refreshActiveEmotes() {
    for record in storage.active {
      ensurePrepared(record)
    }
  }

  func updateClock() {
    let running = policy.allowsAnimation && storage.active.contains { $0.isAnimated }
    clock.setRunning(running)

    if !running {
      metrics.resetCadence()
    }
  }

  @objc private func didReceiveMemoryWarning() {
    decoder.cancelAll()
    storage.clearReusable()
  }
}
