import EmoteRendering
import SwiftUI

private struct ChatEmoteVisibility: ViewModifier {
  @Environment(EmotePlaybackCoordinator.self) private var coordinator
  @State private var isVisible = false
  let message: ChatMessage
  let scope: UUID
  let pixelHeight: Int
  let session: EmoteTextRenderSession

  func body(content: Content) -> some View {
    content
      .onGeometryChange(for: Bool.self) { geometry in
        let frame = geometry.frame(in: .scrollView(axis: .vertical))

        guard frame.height > 0,
          let bounds = geometry.bounds(of: .scrollView(axis: .vertical))
        else { return false }

        return frame.intersects(CGRect(origin: .zero, size: bounds.size))
      } action: { visible in
        isVisible = visible
        publishVisibility()
      }
      .onChange(of: pixelHeight) { publishVisibility() }
      .onChange(of: message.content) { publishVisibility() }
      .onAppear { publishVisibility() }
      .onDisappear { publishVisibility(false) }
  }

  private func publishVisibility(_ visible: Bool? = nil) {
    session.setVisible(
      visible ?? isVisible,
      messageID: message.id,
      scope: scope,
      coordinator: coordinator
    )
  }
}

extension View {
  func tracksChatEmoteVisibility(
    for message: ChatMessage,
    scope: UUID,
    pixelHeight: Int,
    session: EmoteTextRenderSession
  ) -> some View {
    modifier(
      ChatEmoteVisibility(
        message: message, scope: scope, pixelHeight: pixelHeight, session: session))
  }
}
