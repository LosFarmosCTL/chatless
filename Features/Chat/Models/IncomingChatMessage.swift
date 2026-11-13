import Foundation
import TwitchIRC

public struct IncomingChatMessage: Hashable, Identifiable, Sendable {
  public let id: String
  public let channelID: String

  public let authorID: String
  public let authorLogin: String
  public let authorDisplayName: String
  public let authorColorHex: String?

  public let badges: [Badge]
  public let badgeInfo: [BadgeInfo]

  public let sentAt: Date?
  public let rawText: String
  public let isAction: Bool

  public let twitchEmotes: [IncomingChatEmote]

  public init(
    id: String,
    channelID: String,
    authorID: String,
    authorLogin: String,
    authorDisplayName: String,
    authorColorHex: String? = nil,
    badges: [Badge] = [],
    badgeInfo: [BadgeInfo] = [],
    sentAt: Date? = nil,
    rawText: String,
    isAction: Bool = false,
    twitchEmotes: [IncomingChatEmote] = []
  ) {
    self.id = id
    self.channelID = channelID

    self.authorID = authorID
    self.authorLogin = authorLogin
    self.authorDisplayName = authorDisplayName
    self.authorColorHex = authorColorHex

    self.badges = badges
    self.badgeInfo = badgeInfo

    self.sentAt = sentAt
    self.rawText = rawText
    self.isAction = isAction

    self.twitchEmotes = twitchEmotes
  }
}
