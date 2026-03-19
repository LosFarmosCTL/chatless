import Shared
import SwiftData
import SwiftUI
import TwitchSession

public struct ChatListView: View {
  @Environment(\.modelContext) private var modelContext

  @Query(
    filter: #Predicate<AddedChannel> { $0.pinnedIndex == nil }
  ) private var channels: [AddedChannel]

  @Query(
    filter: #Predicate<AddedChannel> { $0.pinnedIndex != nil },
    sort: \AddedChannel.pinnedIndex,
    order: .reverse
  ) private var pinnedChannels: [AddedChannel]

  public init() {}

  // TODO: use TipKit to inform the user about the ability to pin channels
  // the tip should be shown onnce a user had added a certain number of channels
  // and be dismissed as soon as the user has pinned a channel at least once
  public var body: some View {
    List {
      if !pinnedChannels.isEmpty {
        Section(header: Text("Pinned Channels")) {
          ChatList(
            channels: pinnedChannels,
            onUnpin: unpin,
            onDelete: deleteChannels,
            onMove: moveChannels
          )
        }

        Section(header: Text("Channels")) {
          ChatList(
            channels: channels,
            onPin: pin,
            onDelete: deleteChannels,
            onMove: moveChannels
          )
        }
      } else {
        ChatList(
          channels: channels,
          onPin: pin,
          onDelete: deleteChannels,
          onMove: moveChannels
        )
      }
    }
    .listStyle(.plain)
    .contentMargins(.top, 0)
  }

  private func pin(channel: AddedChannel) {
    do {
      try modelContext.transaction {
        channel.pinnedIndex = (pinnedChannels.first?.pinnedIndex ?? -1) + 1
        normalizePinnedIndices(for: pinnedChannels.filter { $0.id != channel.id })
      }
    } catch {
      modelContext.rollback()
    }
  }

  private func unpin(channel: AddedChannel) {
    do {
      try modelContext.transaction {
        channel.pinnedIndex = nil
        normalizePinnedIndices(for: pinnedChannels.filter { $0.id != channel.id })
      }
    } catch {
      modelContext.rollback()
    }
  }

  private func moveChannels(from source: IndexSet, to destination: Int, isPinned: Bool) {
    guard isPinned else { return }

    do {
      try modelContext.transaction {
        var revisedChannels = pinnedChannels
        revisedChannels.move(fromOffsets: source, toOffset: destination)
        normalizePinnedIndices(for: revisedChannels)
      }
    } catch {
      modelContext.rollback()
    }
  }

  private func deleteChannels(at offsets: IndexSet, isPinned: Bool) {
    do {
      try modelContext.transaction {
        let sourceChannels = isPinned ? pinnedChannels : channels
        let channelsToDelete = offsets.map { sourceChannels[$0] }

        channelsToDelete.forEach(modelContext.delete)

        if isPinned {
          var revisedChannels = sourceChannels
          revisedChannels.remove(atOffsets: offsets)
          normalizePinnedIndices(for: revisedChannels)
        }
      }
    } catch {
      modelContext.rollback()
    }
  }

  private func normalizePinnedIndices(for channels: [AddedChannel]) {
    let maxIndex = channels.count - 1
    for (index, channel) in channels.enumerated() {
      channel.pinnedIndex = maxIndex - index
    }
  }
}

private struct ChatList: View {
  @Environment(ChannelStatusStore.self) private var channelStatusStore

  private let channels: [AddedChannel]

  private let onPin: ((AddedChannel) -> Void)?
  private let onUnpin: ((AddedChannel) -> Void)?

  private let onDelete: (IndexSet, _ isPinned: Bool) -> Void
  private let onMove: (IndexSet, Int, _ isPinned: Bool) -> Void

  private var isPinned: Bool { onPin == nil }

  init(
    channels: [AddedChannel],
    onPin: ((AddedChannel) -> Void)? = nil,
    onUnpin: ((AddedChannel) -> Void)? = nil,
    onDelete: @escaping (IndexSet, _ isPinned: Bool) -> Void,
    onMove: @escaping (IndexSet, Int, _ isPinned: Bool) -> Void
  ) {
    self.channels = channels

    self.onPin = onPin
    self.onUnpin = onUnpin

    self.onDelete = onDelete
    self.onMove = onMove
  }

  public var body: some View {
    ForEach(channels, id: \.id) { channel in
      NavigationLink(value: AppRoute.chat(channelID: channel.id)) {
        let status = channelStatusStore.status(for: channel.id)

        ChatListRowView(
          displayName: channel.displayName,
          profileImageURL: channel.profileImageURL,
          isLive: status?.isLive ?? false,
          title: status?.title
        )
      }
      .swipeActions(edge: .leading) {
        if let pinAction = onPin {
          Button(role: .destructive) {
            withAnimation { pinAction(channel) }
          } label: {
            Label("Pin", systemImage: "pin.fill")
          }
          .tint(.yellow)
        } else if let unpinAction = onUnpin {
          Button(role: .destructive) {
            withAnimation { unpinAction(channel) }
          } label: {
            Label("Unpin", systemImage: "pin.slash.fill")
          }
          .tint(.gray)
        }
      }
    }
    .onDelete { offsets in
      withAnimation { onDelete(offsets, isPinned) }
    }
    .onMove { source, destination in
      withAnimation { onMove(source, destination, isPinned) }
    }
    .moveDisabled(!isPinned)
    .listSectionSeparator(.hidden, edges: .top)
  }
}
