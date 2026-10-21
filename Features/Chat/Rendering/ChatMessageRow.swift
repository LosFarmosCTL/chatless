import EmoteRendering
import Emotes
import Shared
import SwiftUI

struct ChatMessageRow: View {
  @Environment(\.displayScale) private var displayScale
  @Environment(\.locale) private var locale
  @Environment(\.timeZone) private var timeZone
  @Environment(AppPreferences.self) private var preferences
  @Environment(EmotePlaybackCoordinator.self) private var coordinator

  @State private var textCache = ChatMessageTextCache()
  @State private var emoteSession = EmoteTextRenderSession()

  let message: ChatMessage
  let emoteHeight: CGFloat
  let visibilityScope: UUID
  let onEmoteTap: (EmoteDefinition) -> Void

  var body: some View {
    let emotes = emoteSession.snapshot(
      definitions: message.content.definitions,
      emoteHeight: emoteHeight,
      pixelHeight: pixelHeight,
      coordinator: coordinator
    )

    let text = textCache.text(
      message: message,
      emotes: emotes,
      style: .init(
        emoteHeight: emoteHeight,
        showTimestamps: preferences.chat.showTimestamps,
        locale: locale,
        timeZone: timeZone
      )
    )

    text
      .font(.body)
      .textRenderer(ChatMessageTextRenderer(emotes: emotes))
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(.rect)
      .onTapGesture(count: 1, coordinateSpace: .local) { location in
        guard let emote = emoteSession.emote(at: location) else { return }

        onEmoteTap(emote)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 3)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(message.accessibilityText)
      .accessibilityActions {
        ForEach(message.content.definitions, id: \.self) { definition in
          Button("Show \(definition.name) emote") { onEmoteTap(definition) }
        }
      }
      .tracksChatEmoteVisibility(
        for: message,
        scope: visibilityScope,
        pixelHeight: pixelHeight,
        session: emoteSession
      )
  }

  private var pixelHeight: Int {
    max(Int(ceil(emoteHeight * displayScale)), 1)
  }
}
