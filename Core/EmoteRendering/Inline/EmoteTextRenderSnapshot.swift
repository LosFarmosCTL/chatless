import Emotes
import SwiftUI

@MainActor
public struct EmoteTextRenderSnapshot {
  public let layout: EmoteTextLayout

  private let assets: [EmoteRenderKey: EmoteAssetRecord]
  private let keysByDefinition: [EmoteDefinition: EmoteRenderKey]
  // Change renderer identity without letting retained snapshots pin decoded images.
  private let frameIdentities: [EmoteRenderKey: ObjectIdentifier]
  private let emoteHeight: CGFloat
  private let hitMap: EmoteHitMap

  init(
    assets: [EmoteRenderKey: EmoteAssetRecord],
    keysByDefinition: [EmoteDefinition: EmoteRenderKey],
    layout: EmoteTextLayout,
    emoteHeight: CGFloat,
    hitMap: EmoteHitMap
  ) {
    self.assets = assets
    self.keysByDefinition = keysByDefinition
    frameIdentities = assets.compactMapValues { $0.currentImage.map(ObjectIdentifier.init) }
    self.layout = layout
    self.emoteHeight = emoteHeight
    self.hitMap = hitMap
  }

  public func text(for occurrence: EmoteOccurrence) -> Text {
    let keys = occurrence.definitions.map { keysByDefinition[$0] }

    guard let baseKey = keys.first ?? nil, case .slot(let aspectRatio) = layout.states[baseKey]
    else {
      return Text(occurrence.definitions.map(\.name).joined(separator: " "))
    }

    let slotWidth = max(emoteHeight * aspectRatio, emoteHeight * 0.25)
    let placeholder = Image(
      size: CGSize(width: slotWidth, height: emoteHeight),
      label: Text(occurrence.base.name)
    ) { _ in }

    return Text("\(placeholder)")
      .customAttribute(EmoteTextAttribute(keys: keys, definition: occurrence.base))
  }

  public func draw(
    layout: Text.Layout,
    in context: inout GraphicsContext,
    fallback: (Text.Layout.Run, inout GraphicsContext) -> Void
  ) {
    _ = frameIdentities
    var resolvedImages: [EmoteRenderKey: GraphicsContext.ResolvedImage] = [:]
    var hitRegions: [EmoteHitRegion] = []

    for line in layout {
      for run in line {
        guard let attribute = run[EmoteTextAttribute.self] else {
          fallback(run, &context)
          continue
        }

        let bounds = run.typographicBounds.rect
        hitRegions.append(EmoteHitRegion(definition: attribute.definition, rect: bounds))
        var drewBase = false

        for (index, key) in attribute.keys.enumerated() {
          guard let key, case .ready(let image, let aspectRatio) = assets[key]?.state else {
            continue
          }

          let height = bounds.height
          let width = index == 0 ? min(bounds.width, height * aspectRatio) : height * aspectRatio
          let rect = CGRect(
            x: bounds.midX - width / 2,
            y: bounds.midY - height / 2,
            width: width,
            height: height
          )
          let resolved = resolvedImages[key] ?? context.resolve(Image(uiImage: image))
          resolvedImages[key] = resolved
          context.draw(resolved, in: rect)

          if index == 0 {
            drewBase = true
          }
        }

        if drewBase == false, let baseKey = attribute.keys.first ?? nil,
          case .failed = assets[baseKey]?.state
        {
          continue
        }

        if drewBase == false {
          drawPlaceholder(in: bounds, context: &context)
        }
      }
    }

    hitMap.replaceRegionsIfNeeded(hitRegions)
  }

  private func drawPlaceholder(in bounds: CGRect, context: inout GraphicsContext) {
    let side = min(bounds.width, bounds.height) * 0.72
    let rect = CGRect(
      x: bounds.midX - side / 2,
      y: bounds.midY - side / 2,
      width: side,
      height: side
    )
    context.fill(
      Path(roundedRect: rect, cornerRadius: side * 0.18),
      with: .color(.secondary.opacity(0.22))
    )
  }
}
