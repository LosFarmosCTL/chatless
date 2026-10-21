import Emotes

extension IncomingChatMessage {
  // IRC positions count Unicode scalars. Build fragments in text order from those positions.
  var emoteFragments: [EmoteSourceFragment] {
    let scalars = Array(rawText.unicodeScalars)
    let emotesByOffset = Dictionary(
      uniqueKeysWithValues: twitchEmotes.map {
        ($0.range.lowerBound, $0)
      })

    var fragments: [EmoteSourceFragment] = []
    var cursor = 0
    var textStart = 0

    while cursor < scalars.count {
      guard let emote = emotesByOffset[cursor] else {
        cursor += 1
        continue
      }

      if textStart < cursor {
        let text = String(String.UnicodeScalarView(scalars[textStart..<cursor]))

        fragments.append(.text(text))
      }

      fragments.append(.twitchEmote(name: emote.name, id: emote.id))

      cursor = emote.range.upperBound
      textStart = cursor
    }

    if textStart < scalars.count {
      let text = String(String.UnicodeScalarView(scalars[textStart..<scalars.count]))

      fragments.append(.text(text))
    }

    return fragments
  }
}
