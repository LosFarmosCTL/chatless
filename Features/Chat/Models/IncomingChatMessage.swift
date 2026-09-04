import Foundation

public struct IncomingChatMessage: Hashable, Identifiable, Sendable {
  public let id: String
  public let channelID: String

  public let authorID: String
  public let authorLogin: String
  public let authorDisplayName: String
  public let authorColorHex: String?

  public let badges: [String]
  public let badgeInfo: [String]

  public let sentAt: Date?
  public let rawText: String
  public let isAction: Bool

  public let twitchEmotes: [IncomingChatEmote]

  public let rawEmoteTag: String

  public init(
    id: String,
    channelID: String,
    authorID: String,
    authorLogin: String,
    authorDisplayName: String,
    authorColorHex: String? = nil,
    badges: [String] = [],
    badgeInfo: [String] = [],
    sentAt: Date? = nil,
    rawText: String,
    isAction: Bool = false,
    twitchEmotes: [IncomingChatEmote] = [],
    rawEmoteTag: String = ""
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
    self.rawEmoteTag = rawEmoteTag
  }
}
