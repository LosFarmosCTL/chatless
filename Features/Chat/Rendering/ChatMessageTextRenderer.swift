import EmoteRendering
import SwiftUI

struct ChatMessageTextRenderer: @MainActor TextRenderer {
  let emotes: EmoteTextRenderSnapshot

  @MainActor func draw(layout: Text.Layout, in context: inout GraphicsContext) {
    emotes.draw(layout: layout, in: &context) { run, context in
      context.draw(run)
    }
  }
}
