import SwiftData
import SwiftUI
import TwitchSession

public struct ChatListView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.channelEventRegistry) private var channelRegistry: ChannelEventStateRegistry!

  @Query private var channels: [ChatChannel]

  @State private var newChannelID = ""
  @State private var trackedChannelIDs: Set<String> = []

  public init() {}

  public var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 12) {
        // TODO: remove this, only for testing
        TextField("Add channel ID", text: $newChannelID)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .textFieldStyle(.roundedBorder)

        Button("Add") {
          addChannel()
        }
        .buttonStyle(.borderedProminent)
        .disabled(newChannelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }

      List {
        ForEach(channels, id: \.channelID) { channel in
          NavigationLink(value: channel.channelID) {
            Text(channel.channelID)
          }
        }
        .onDelete(perform: deleteChannels)
      }
      .listStyle(.plain)
    }
    .navigationDestination(for: String.self) { channelID in
      ChatView(state: channelRegistry.getOrCreateChannel(channelID))
    }
  }

  private func addChannel() {
    let trimmed = newChannelID.trimmingCharacters(in: .whitespacesAndNewlines)
    self.newChannelID = ""

    guard !trimmed.isEmpty else { return }
    guard !channels.contains(where: { $0.channelID == trimmed }) else { return }

    modelContext.insert(ChatChannel(channelID: trimmed))
    try? modelContext.save()
  }

  private func deleteChannels(at offsets: IndexSet) {
    for index in offsets {
      let channel = channels[index]
      modelContext.delete(channel)
    }

    try? modelContext.save()
  }

}
