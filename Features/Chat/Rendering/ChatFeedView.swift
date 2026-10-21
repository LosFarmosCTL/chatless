import EmoteRendering
import Emotes
import Shared
import SwiftUI

struct ChatFeedView: View {
  @Environment(AppPreferences.self) private var preferences
  @ScaledMetric(relativeTo: .body) private var emoteHeightScale = 1.0

  @State private var visibilityScope = UUID()
  @State private var presentedEmote: EmoteDefinition?

  let feed: ChatFeedStore

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 0) {
        ForEach(feed.messages) { message in
          ChatMessageRow(
            message: message,
            emoteHeight: emoteHeight,
            visibilityScope: visibilityScope,
            onEmoteTap: { presentedEmote = $0 }
          )
        }
      }
      .scrollTargetLayout()
    }
    .followsChatBottom(when: feed.messages.last?.id)
    .coordinatesEmotePlayback(visibilityScope: visibilityScope)
    .background(.background)
    .sheet(item: $presentedEmote) { emote in
      EmoteDetailSheet(emote: emote)
        .presentationDragIndicator(.visible)
    }
  }

  private var emoteHeight: CGFloat {
    CGFloat(preferences.chat.emoteHeight) * emoteHeightScale
  }
}
