import CoreGraphics
import Emotes
import Foundation
import Observation

@MainActor
@Observable public final class EmoteTextRenderSession {
  private var isVisible = false
  private let owner = UUID()
  private let hitMap = EmoteHitMap()
  @ObservationIgnored private var definitions: [EmoteDefinition] = []
  @ObservationIgnored private var pixelHeight = 0
  @ObservationIgnored private weak var coordinator: EmotePlaybackCoordinator?
  @ObservationIgnored private var assets: [EmoteRenderKey: EmoteAssetRecord] = [:]
  @ObservationIgnored private var keysByDefinition: [EmoteDefinition: EmoteRenderKey] = [:]
  @ObservationIgnored private var layout = EmoteTextLayout(states: [:])

  public init() {}

  public func snapshot(
    definitions: [EmoteDefinition],
    emoteHeight: CGFloat,
    pixelHeight: Int,
    coordinator: EmotePlaybackCoordinator
  ) -> EmoteTextRenderSnapshot {
    if self.definitions != definitions || self.pixelHeight != pixelHeight
      || self.coordinator !== coordinator
    {
      prepare(definitions, pixelHeight: pixelHeight, coordinator: coordinator)
    }

    // Reading each asset's observable state subscribes this row to its own assets.
    let next = EmoteTextLayout(
      states: assets.mapValues {
        isVisible ? $0.state.layoutState : layout.states[$0.selection.key] ?? .slot(aspectRatio: 1)
      })
    coordinator.recordPresentation(layoutChanged: layout != next)
    layout = next

    return EmoteTextRenderSnapshot(
      assets: isVisible ? assets : [:], keysByDefinition: keysByDefinition, layout: layout,
      emoteHeight: emoteHeight, hitMap: hitMap)
  }

  private func prepare(
    _ definitions: [EmoteDefinition], pixelHeight: Int, coordinator: EmotePlaybackCoordinator
  ) {
    self.definitions = definitions
    self.pixelHeight = pixelHeight
    self.coordinator = coordinator
    assets.removeAll(keepingCapacity: true)
    keysByDefinition.removeAll(keepingCapacity: true)

    for definition in definitions {
      guard let selection = EmoteAssetSelection(definition: definition, pixelHeight: pixelHeight)
      else { continue }

      keysByDefinition[definition] = selection.key
      assets[selection.key] = coordinator.asset(for: selection)
    }
  }

  public func setVisible(
    _ visible: Bool, messageID: String, scope: UUID, coordinator: EmotePlaybackCoordinator
  ) {
    isVisible = visible
    coordinator.consumers.set(
      .row(scope: scope, message: messageID), assets: visible ? Array(assets.values) : nil,
      owner: owner)
  }

  public func emote(at location: CGPoint) -> EmoteDefinition? {
    hitMap.emote(at: location)
  }
}
