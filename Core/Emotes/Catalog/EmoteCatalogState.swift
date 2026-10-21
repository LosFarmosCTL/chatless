import Foundation

struct EmoteCatalogState {
  private(set) var channelIDs: Set<String> = []
  private(set) var snapshots: [EmoteCatalogKey: ProviderCatalogSnapshot] = [:]
  private var updates: [String: EmoteCatalogUpdate] = [:]
  private var readyChannels: Set<String> = []
  private var revision: UInt64 = 0

  var liveSubscriptions: Set<EmoteLiveSubscription> {
    Set(snapshots.values.flatMap(\.liveSubscriptions))
  }

  mutating func syncChannels(_ ids: Set<String>) {
    channelIDs = ids
    snapshots = snapshots.filter {
      switch $0.key.scope {
      case .global: true
      case .channel(let id): ids.contains(id)
      }
    }
    updates = updates.filter { ids.contains($0.key) }
    readyChannels.formIntersection(ids)
  }

  func update(for channelID: String) -> EmoteCatalogUpdate {
    updates[channelID] ?? .init(catalog: .init(channelID: channelID), reason: .initial)
  }

  mutating func restore(_ cached: [ProviderCatalogSnapshot]) {
    for snapshot in cached where snapshots[snapshot.key] == nil {
      apply(snapshot)
    }
  }

  mutating func apply(_ snapshot: ProviderCatalogSnapshot) {
    if case .channel(let id) = snapshot.key.scope, !channelIDs.contains(id) { return }

    snapshots[snapshot.key] = snapshot
  }

  func keys(provider: EmoteProvider, scope: EmoteInvalidationScope) -> [EmoteCatalogKey] {
    switch scope {
    case .global: [.init(provider: provider, scope: .global)]
    case .channel(let id):
      channelIDs.contains(id) ? [.init(provider: provider, scope: .channel(id))] : []
    case .provider:
      [.init(provider: provider, scope: .global)]
        + channelIDs.sorted().map { .init(provider: provider, scope: .channel($0)) }
    }
  }

  func refreshWork(force: Bool, at date: Date = .now) -> [EmoteCatalogKey] {
    EmoteProviders.order.flatMap { provider in
      keys(provider: provider, scope: .provider).filter { key in
        guard !force, let snapshot = snapshots[key] else { return true }

        return date.timeIntervalSince(snapshot.fetchedAt)
          >= EmoteProviders.refreshInterval(for: provider)
      }
    }
  }

  mutating func markReady(_ ids: Set<String>) -> Set<String> {
    let added = ids.subtracting(readyChannels)
    readyChannels.formUnion(ids)
    return added
  }

  mutating func rebuild(channelID: String, reason: EmoteCatalogUpdateReason) -> EmoteCatalogUpdate?
  {
    var definitions: [String: EmoteDefinition] = [:]
    let scopes: [EmoteCatalogScope] = [.global, .channel(channelID)]

    // Channel scope wins over global scope, then provider precedence within each scope.
    for scope in scopes {
      for provider in EmoteProviders.order {
        for definition in snapshots[.init(provider: provider, scope: scope)]?.definitions ?? [] {
          definitions[definition.name] = definition
        }
      }
    }

    let unavailable = Set(
      EmoteProviders.order.filter { provider in
        scopes.contains { snapshots[.init(provider: provider, scope: $0)] == nil }
      })
    let previous = updates[channelID]?.catalog

    if reason != .reconciliation,
      previous?.definitionsByName == definitions,
      previous?.isReady == readyChannels.contains(channelID),
      previous?.unavailableProviders == unavailable
    {
      return nil
    }

    revision &+= 1
    let update = EmoteCatalogUpdate(
      catalog: .init(
        channelID: channelID, definitionsByName: definitions, revision: revision,
        isReady: readyChannels.contains(channelID), unavailableProviders: unavailable
      ), reason: reason)
    updates[channelID] = update
    return update
  }
}
