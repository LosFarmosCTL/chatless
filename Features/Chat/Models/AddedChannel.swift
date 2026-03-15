import SwiftData
import SwiftUI
import Twitch

@Model
public final class AddedChannel {
  @Attribute(.unique) public var id: String
  public var login: String
  public var displayName: String
  public var profileImageURL: String

  public init(
    id: String,
    login: String,
    displayName: String,
    profileImageURL: String,
  ) {
    self.id = id
    self.login = login
    self.displayName = displayName
    self.profileImageURL = profileImageURL
  }

  @ModelActor
  public actor Updater {
    public func updateChannels(with userData: [Twitch.User]) {
      let userIDs = userData.map(\.id)
      let fetchDescriptor = FetchDescriptor<AddedChannel>(
        predicate: #Predicate { userIDs.contains($0.id) }
      )

      guard let channels = try? modelContext.fetch(fetchDescriptor) else { return }
      let channelMap = Dictionary(uniqueKeysWithValues: channels.map { ($0.id, $0) })

      for data in userData {
        if let channel = channelMap[data.id] {
          channel.login = data.login
          channel.displayName = data.displayName
          channel.profileImageURL = data.profileImageUrl
        }
      }

      try? modelContext.save()
    }
  }
}
