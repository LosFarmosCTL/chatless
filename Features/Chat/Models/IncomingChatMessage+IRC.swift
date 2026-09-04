import Foundation
import TwitchIRC

extension IncomingChatMessage {
  init(message: PrivateMessage, channelID: String) {
    let content = message.message
    let isAction = content.hasPrefix("\u{01}ACTION ") && content.hasSuffix("\u{01}")

    let text =
      if isAction {
        String(
          content.unicodeScalars
            .dropFirst(8)
            .dropLast())
      } else { content }

    self.init(
      id: message.id,
      channelID: channelID,
      authorID: message.userId,
      authorLogin: message.userLogin,
      authorDisplayName: message.displayName,
      authorColorHex: message.color.isEmpty ? nil : message.color,
      badges: message.badges,
      badgeInfo: message.badgeInfo,
      sentAt: Date(timeIntervalSince1970: Double(message.tmiSentTs) / 1_000),
      rawText: text,
      isAction: isAction,
      twitchEmotes: Self.emotes(text: text, tag: message.emotes),
      rawEmoteTag: message.emotes
    )
  }

  private static func emotes(text: String, tag: String) -> [IncomingChatEmote] {
    let scalars = Array(text.unicodeScalars)
    var result: [IncomingChatEmote] = []

    for group in tag.split(separator: "/") {
      let parts = group.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)

      guard parts.count == 2, !parts[0].isEmpty else { continue }

      for occurrence in parts[1].split(separator: ",") {
        let bounds = occurrence.split(separator: "-", omittingEmptySubsequences: false)

        guard bounds.count == 2,
          let start = Int(bounds[0]),
          let end = Int(bounds[1]),
          start >= 0,
          end >= start,
          end < scalars.count
        else { continue }

        let range = start..<(end + 1)

        result.append(
          .init(
            id: String(parts[0]),
            name: String(String.UnicodeScalarView(scalars[range])),
            range: range
          )
        )
      }
    }

    return result
  }
}
