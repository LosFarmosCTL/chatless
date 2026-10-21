import Foundation

extension EmoteCatalogStore {
  func prepareCatalogs(cached: [ProviderCatalogSnapshot], reason: EmoteCatalogUpdateReason) {
    catalogs.restore(cached)
    queuePublication(catalogs.channelIDs, reason: .initial)
    enqueueRefresh(reason: reason)
    liveSubscriptions = catalogs.liveSubscriptions
    live.restartAll(
      channels: catalogs.channelIDs, subscriptions: liveSubscriptions,
      onInvalidation: invalidationHandler)
  }

  func enqueueRefresh(reason: EmoteCatalogUpdateReason) {
    let work = catalogs.refreshWork(force: reason == .reconciliation)

    enqueue(work, affected: catalogs.channelIDs, reason: reason)
  }

  func receive(_ event: EmoteLiveEvent, provider: EmoteProvider) {
    let scope: EmoteInvalidationScope
    let reason: EmoteCatalogUpdateReason

    switch event {
    case .changed(let changedScope):
      scope = changedScope
      reason = .live
    case .reconnected:
      scope = .provider
      reason = .reconciliation
    }

    let work = catalogs.keys(provider: provider, scope: scope)
    let affected = if case .channel(let id) = scope { Set([id]) } else { catalogs.channelIDs }
    enqueue(work, affected: affected, reason: reason, debounce: true)
  }

  func updateReadiness() {
    let ready = catalogs.channelIDs.filter { channelID in
      !refreshes.contains { key, refresh in
        key.affects(channelID) && (refresh.task?.isCancelled != true || pending.contains(key))
      }
    }

    queuePublication(catalogs.markReady(ready), reason: .live)
  }

  func completeReconciliationIfReady() {
    guard !refreshes.values.contains(where: { $0.reason == .reconciliation }) else { return }

    queuePublication(reconciliationChannels, reason: .reconciliation)
    reconciliationChannels.removeAll()
  }

  func queuePublication(_ ids: Set<String>, reason: EmoteCatalogUpdateReason) {
    for id in ids {
      if reason == .reconciliation || publications[id] == nil {
        publications[id] = reason
      }
    }

    schedulePublication()
  }

  private func schedulePublication() {
    guard publicationTask == nil, !publications.isEmpty else { return }

    publicationTask = Task { [weak self] in
      await Task.yield()
      guard !Task.isCancelled else { return }

      self?.publishPending()
    }
  }

  private func publishPending() {
    publicationTask = nil
    let pending = publications
    publications.removeAll()

    for (id, reason) in pending {
      if let update = catalogs.rebuild(
        channelID: id,
        reason: reason
      ) {
        onUpdate?(update)
      }
    }

    let subscriptions = catalogs.liveSubscriptions

    if liveSubscriptions != subscriptions {
      liveSubscriptions = subscriptions
      live.restartSevenTV(subscriptions: subscriptions, onInvalidation: invalidationHandler)
    }
  }
}
