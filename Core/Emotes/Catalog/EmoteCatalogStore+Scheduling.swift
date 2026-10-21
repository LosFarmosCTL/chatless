import Foundation

extension EmoteCatalogStore {
  func enqueue(
    _ work: [EmoteCatalogKey], affected: Set<String>, reason: EmoteCatalogUpdateReason,
    debounce: Bool = false
  ) {
    if reason == .reconciliation {
      reconciliationChannels.formUnion(affected)
    }

    for key in work {
      if refreshes[key] == nil {
        refreshes[key] = Refresh(reason: reason)
      } else if reason == .reconciliation {
        refreshes[key]?.reason = reason
      }

      let invalidating = reason == .reconciliation || debounce
      if let task = refreshes[key]?.task, !task.isCancelled, !invalidating { continue }
      if !pending.contains(key) { pending.append(key) }
    }

    scheduleRefreshes(debounce: debounce)
    updateReadiness()
    completeReconciliationIfReady()
  }

  func cancelRefreshes() {
    wakeTask?.cancel()
    wakeTask = nil
    pending.removeAll()

    // Cancelled requests keep their slots until they return, including across restarts.
    for (key, refresh) in refreshes {
      if let task = refresh.task {
        task.cancel()
        refreshes[key]?.reason = .initial
      } else {
        refreshes.removeValue(forKey: key)
      }
    }
  }

  private func scheduleRefreshes(debounce: Bool) {
    guard !pending.isEmpty else { return }

    if debounce {
      guard wakeTask == nil else { return }

      wakeTask = Task { [weak self] in
        do {
          try await Task.sleep(for: .milliseconds(300))
        } catch {
          return
        }

        self?.wakeTask = nil
        self?.startPending()
      }
    } else {
      wakeTask?.cancel()
      wakeTask = nil
      startPending()
    }
  }

  private func startPending() {
    guard wakeTask == nil else { return }

    while refreshes.values.count(where: { $0.task != nil }) < 4,
      let index = pending.firstIndex(where: { refreshes[$0]?.task == nil })
    {
      let key = pending.remove(at: index)
      refreshes[key]?.task = Task { [weak self, load, snapshots] in
        let snapshot = await EmoteProviders.fetch(key, using: load)

        if !Task.isCancelled, self?.pending.contains(key) == false, let snapshot {
          self?.catalogs.apply(snapshot)
          self?.queuePublication(key.channels(in: self?.catalogs.channelIDs ?? []), reason: .live)
          await snapshots.save(snapshot)
        }

        self?.finish(key, cancelled: Task.isCancelled)
      }
    }
  }

  private func finish(_ key: EmoteCatalogKey, cancelled: Bool) {
    refreshes[key]?.task = nil

    if !pending.contains(key) {
      refreshes.removeValue(forKey: key)
    }

    if !cancelled {
      updateReadiness()
      completeReconciliationIfReady()
    }

    startPending()
  }
}
