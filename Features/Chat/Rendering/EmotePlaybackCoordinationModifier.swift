import EmoteRendering
import SwiftUI

extension View {
  func coordinatesEmotePlayback(visibilityScope: UUID) -> some View {
    modifier(
      EmotePlaybackCoordinationModifier(
        visibilityScope: visibilityScope
      )
    )
  }
}

private struct EmotePlaybackCoordinationModifier: ViewModifier {
  @Environment(EmotePlaybackCoordinator.self) private var coordinator

  let visibilityScope: UUID

  func body(content: Content) -> some View {
    content
      .onScrollPhaseChange { _, phase in
        coordinator.setScrolling(phase != .idle, scope: visibilityScope)
      }
      .onDisappear { coordinator.clearVisibleMessages(scope: visibilityScope) }
  }
}
