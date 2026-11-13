import Foundation
import TwitchIRC

extension IncomingChatMessage {
  init(message: PrivateMessage, channelID: String) {
    self.init(
      id: message.id,
      channelID: channelID,
      authorID: message.userID,
      authorLogin: message.userLogin,
      authorDisplayName: message.displayName,
      authorColorHex: message.color,
      badges: message.badges,
      badgeInfo: message.badgeInfo,
      sentAt: message.timestampMilliseconds.map {
        Date(timeIntervalSince1970: Double($0) / 1_000)
      },
      rawText: message.message,
      isAction: message.isAction,
      twitchEmotes: message.emotes.compactMap { emote in
        guard let range = emote.range.stringRange(in: message.message) else { return nil }
        return .init(id: emote.id, name: emote.name, range: range)
      }
    )
  }
}
