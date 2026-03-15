import Shared
import SwiftData
import SwiftUI
import TwitchSession

public struct ChatListView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(ChannelStatusStore.self) private var channelStatusStore

  @Query private var channels: [AddedChannel]

  public init() {}

  public var body: some View {
    VStack(spacing: 12) {
      List {
        ForEach(channels, id: \.id) { channel in
          NavigationLink(value: AppRoute.chat(channelID: channel.id)) {
            Text(
              channel.displayName
                + " (\(channelStatusStore.status(for: channel.id)?.isLive ?? false ? "LIVE" : "OFFLINE"))"
            )
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
