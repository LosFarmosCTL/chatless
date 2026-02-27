import Foundation
import SwiftData

@Model
public final class ChatChannel {
  @Attribute(.unique) public var channelID: String

  public init(channelID: String) {
    self.channelID = channelID
  }
}
