import Foundation

@MainActor
public final class EmoteCatalogStore {
  public var onUpdate: (@MainActor (EmoteCatalogUpdate) -> Void)?

  let snapshots: any EmoteSnapshotStoring
  let live: EmoteLiveConnectionCoordinator
  let load: EmoteProviders.Loader

  struct Refresh {
    var reason: EmoteCatalogUpdateReason
    var task: Task<Void, Never>?
  }

  var refreshes: [EmoteCatalogKey: Refresh] = [:]
  var pending: [EmoteCatalogKey] = []
  var wakeTask: Task<Void, Never>?

  var catalogs = EmoteCatalogState()
  var publications: [String: EmoteCatalogUpdateReason] = [:]
  var reconciliationChannels: Set<String> = []
  var publicationTask: Task<Void, Never>?
  var liveSubscriptions: Set<EmoteLiveSubscription> = []

  private var isSceneActive = true
  private var refreshTask: Task<Void, Never>?

  public convenience init() {
    self.init(snapshots: EmoteSnapshotStore())
  }

  init(
    snapshots: any EmoteSnapshotStoring,
    load: @escaping EmoteProviders.Loader = { try await EmoteProviders.load($0) }
  ) {
    self.snapshots = snapshots
    live = EmoteLiveConnectionCoordinator()
    self.load = load
  }

  isolated deinit {
    refreshTask?.cancel()
    publicationTask?.cancel()
    cancelRefreshes()
    live.stop()
  }

  public func update(for channelID: String) -> EmoteCatalogUpdate {
    catalogs.update(for: channelID)
  }

  public func syncChannels(_ ids: Set<String>) {
    guard ids != catalogs.channelIDs else { return }

    catalogs.syncChannels(ids)
    restart(reason: .initial)
  }

  public func setSceneActive(_ active: Bool) {
    guard isSceneActive != active else { return }

    isSceneActive = active
    restart(reason: .reconciliation)
  }

  public func refresh() {
    guard isSceneActive, !catalogs.channelIDs.isEmpty else { return }

    enqueueRefresh(reason: .reconciliation)
  }

  private func restart(reason: EmoteCatalogUpdateReason) {
    refreshTask?.cancel()
    refreshTask = nil
    publicationTask?.cancel()
    publicationTask = nil
    cancelRefreshes()
    live.stop()
    publications.removeAll()
    reconciliationChannels.removeAll()

    guard isSceneActive, !catalogs.channelIDs.isEmpty else { return }

    refreshTask = Task { [weak self, snapshots] in
      let cached = await snapshots.loadAll()
      guard !Task.isCancelled else { return }

      self?.prepareCatalogs(cached: cached, reason: reason)

      while !Task.isCancelled {
        do {
          try await Task.sleep(for: .seconds(60))
        } catch {
          return
        }

        self?.enqueueRefresh(reason: .live)
      }
    }
  }

  var invalidationHandler: EmoteLiveConnectionCoordinator.InvalidationHandler {
    { [weak self] provider, event in
      self?.receive(event, provider: provider)
    }
  }
}
