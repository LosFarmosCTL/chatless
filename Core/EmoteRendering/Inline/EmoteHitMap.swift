import Emotes
import Foundation

@MainActor
final class EmoteHitMap {
  private var regions: [EmoteHitRegion] = []

  func replaceRegionsIfNeeded(_ newRegions: [EmoteHitRegion]) {
    guard regions != newRegions else { return }

    regions = newRegions
  }

  func emote(at point: CGPoint) -> EmoteDefinition? {
    if let exact = regions.first(where: { $0.rect.contains(point) }) {
      return exact.definition
    }

    let nearby = regions.filter { $0.rect.insetBy(dx: -6, dy: -6).contains(point) }

    return nearby.min {
      squaredDistance(from: point, to: $0.rect)
        < squaredDistance(from: point, to: $1.rect)
    }?.definition
  }

  private func squaredDistance(from point: CGPoint, to rect: CGRect) -> CGFloat {
    let deltaX = point.x - rect.midX
    let deltaY = point.y - rect.midY

    return deltaX * deltaX + deltaY * deltaY
  }
}
