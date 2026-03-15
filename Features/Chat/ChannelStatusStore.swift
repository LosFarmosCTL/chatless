import Foundation

@Observable public class ChannelStatusStore {
  public struct Status {
    var isLive: Bool
    var title: String
  }

  private var statusMap: [String: Status] = [:]  // [channelID: Status]

  public init() {}

  public func update(channelID: String, isLive: Bool, title: String) {
    statusMap[channelID] = Status(isLive: isLive, title: title)
  }

  public func status(for channelID: String) -> Status? {
    statusMap[channelID]
  }
}
