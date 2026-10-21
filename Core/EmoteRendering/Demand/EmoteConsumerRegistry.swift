import Foundation

@MainActor
final class EmoteConsumerRegistry {
  enum Consumer: Hashable {
    case row(scope: UUID, message: String)
    case preview(UUID)

    var scope: UUID? {
      guard case .row(let scope, _) = self else { return nil }

      return scope
    }
  }

  private struct Registration {
    let owner: UUID
    let assets: [EmoteAssetRecord]
  }

  private var registrations: [Consumer: Registration] = [:]
  private var demandTask: Task<Void, Never>?

  var onDemandChange: (([EmoteRenderKey: EmoteAssetRecord]) -> Void)?
  var visibleRowCount: Int { registrations.keys.count { $0.scope != nil } }
  var targetPixelHeight: Int {
    registrations.filter { $0.key.scope != nil }.values.flatMap(\.assets)
      .map(\.selection.requestedPixelHeight).max() ?? 0
  }

  func set(_ id: Consumer, assets: [EmoteAssetRecord]?, owner: UUID) {
    let previous = registrations[id]

    if let assets {
      guard
        previous?.owner != owner
          || previous?.assets.map(\.selection.key) != assets.map(\.selection.key)
      else { return }

      registrations[id] = Registration(owner: owner, assets: assets)
    } else {
      // Teardown from a replaced row must not remove its successor's demand.
      guard previous?.owner == owner else { return }

      registrations.removeValue(forKey: id)
    }

    scheduleDemandUpdate()
  }

  func clear(scope: UUID) {
    registrations = registrations.filter { $0.key.scope != scope }
    scheduleDemandUpdate()
  }

  private func scheduleDemandUpdate() {
    guard demandTask == nil else { return }

    demandTask = Task { [weak self] in
      guard let self else { return }

      demandTask = nil
      let assets = registrations.values.flatMap(\.assets)
      onDemandChange?(
        Dictionary(assets.map { ($0.selection.key, $0) }, uniquingKeysWith: { first, _ in first }))
    }
  }
}
