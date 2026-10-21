import EmoteRendering
import Shared
import SwiftUI

@MainActor
final class ChatMessageTextCache {
  struct Style: Equatable {
    let emoteHeight: CGFloat
    let showTimestamps: Bool
    let locale: Locale
    let timeZone: TimeZone
  }

  private struct Key: Equatable {
    let message: ChatMessage
    let layout: EmoteTextLayout
    let style: Style
  }

  private var cachedKey: Key?
  private var cachedText = Text("")

  func text(
    message: ChatMessage,
    emotes: EmoteTextRenderSnapshot,
    style: Style
  ) -> Text {
    let key = Key(
      message: message,
      layout: emotes.layout,
      style: style
    )

    guard cachedKey != key else { return cachedText }

    cachedKey = key

    var result = Text(authorPrefix(for: key))

    for segment in message.content.segments {
      let next: Text

      switch segment {
      case .text(let value):
        next = message.source.isAction ? Text(value).italic() : Text(value)
      case .emote(let occurrence):
        next = emotes.text(for: occurrence)
      }

      result = Text("\(result)\(next)")
    }

    cachedText = result

    return result
  }

  private func authorPrefix(for key: Key) -> AttributedString {
    let message = key.message
    var prefix = AttributedString(message.author + (message.source.isAction ? " " : ": "))
    prefix.font = .body.bold()
    prefix.foregroundColor = message.authorColorHex.flatMap(Color.init(hex:)) ?? .secondary

    guard key.style.showTimestamps, let timestamp = message.source.sentAt else { return prefix }

    let format = Date.FormatStyle(
      date: .omitted, time: .shortened, locale: key.style.locale, timeZone: key.style.timeZone)
    var time = AttributedString(timestamp.formatted(format) + " ")
    time.font = .caption.monospacedDigit()
    time.foregroundColor = .secondary

    return time + prefix
  }
}
