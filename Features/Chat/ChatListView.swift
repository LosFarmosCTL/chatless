import Shared
import SwiftData
import SwiftUI
import TwitchSession

public struct ChatListView: View {
  @Environment(\.modelContext) private var modelContext

  @Query private var channels: [ChatChannel]

  public init() {}

  public var body: some View {
    VStack(spacing: 12) {
      List {
        ForEach(channels, id: \.channelID) { channel in
          NavigationLink(value: AppRoute.chat(channelID: channel.channelID)) {
            Text(channel.channelID)
          }
        }
        .onDelete(perform: deleteChannels)
      }
      .listStyle(.plain)
    }
  }

  private func deleteChannels(at offsets: IndexSet) {
    for index in offsets {
      let channel = channels[index]
      modelContext.delete(channel)
    }

    try? modelContext.save()
  }

}
