import Emotes

extension IncomingChatMessage {
  var emoteFragments: [EmoteSourceFragment] {
    var fragments: [EmoteSourceFragment] = []
    var cursor = rawText.startIndex

    for emote in twitchEmotes.sorted(by: { $0.range.lowerBound < $1.range.lowerBound }) {
      guard emote.range.lowerBound >= cursor else { continue }

      if cursor < emote.range.lowerBound {
        fragments.append(.text(String(rawText[cursor..<emote.range.lowerBound])))
      }

      fragments.append(.twitchEmote(name: emote.name, id: emote.id))
      cursor = emote.range.upperBound
    }

    if cursor < rawText.endIndex {
      fragments.append(.text(String(rawText[cursor...])))
    }

    return fragments
  }
}
