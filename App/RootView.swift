import Auth
import Chat
import Shared
import SwiftData
import SwiftUI
import Twitch
import TwitchSession

struct RootView: View {
  @Environment(AuthenticationStore.self) private var auth
  @Environment(TwitchClientStore.self) private var twitchClientStore

  @Environment(TwitchAPIService.self) private var twitchAPI

  @Environment(GlobalEventState.self) private var globalEventState
  @Environment(ChannelEventStateRegistry.self) private var channelRegistry

  @Environment(ChannelStatusStore.self) private var channelStatusStore

  @Environment(\.modelContext) private var modelContext
  @Query private var channels: [AddedChannel]

  @State private var isRefreshing: Bool = false

  var body: some View {
    ContentView(isRefreshing: isRefreshing)
      .task(id: auth.activeAccount) { await handleAuthChange(auth.activeAccount) }
      .task(id: channels) { channelRegistry.syncChannels(to: Set(channels.map(\.id))) }
      .task(every: .seconds(60), isBusy: $isRefreshing) { await refreshChannels() }
  }

  @MainActor
  private func handleAuthChange(_ activeAccount: ActiveAccount?) async {
    guard let activeAccount else {
      await clearSession()
      return
    }

    await twitchClientStore.activate(account: activeAccount)

    channelRegistry.apply(context: twitchClientStore.context)
    if let context = twitchClientStore.context {
      globalEventState.start(context: context)
    } else {
      globalEventState.stop()
    }
  }

  @MainActor
  private func clearSession() async {
    await twitchClientStore.deactivate()

    channelRegistry.apply(context: nil)
    globalEventState.stop()
  }

  private func refreshChannels() async {
    let updater = AddedChannel.Updater(modelContainer: modelContext.container)

    for channelBatch in channels.chunked(into: 100) {
      async let usersRes = twitchAPI.request(.getUsers(ids: channelBatch.map(\.id)))
      async let streamsRes = twitchAPI.request(.getStreams(userIDs: channelBatch.map(\.id)))

      let users = (try? await usersRes) ?? []
      let streams = (try? await streamsRes)?.0 ?? []

      await updater.updateChannels(with: users)

      let liveSet = Set(streams.map(\.userID))
      let titleMap = Dictionary(uniqueKeysWithValues: streams.map { ($0.userID, $0.title) })
      for channel in channelBatch {
        channelStatusStore.update(
          channelID: channel.id,
          isLive: liveSet.contains(channel.id),
          title: titleMap[channel.id] ?? "")
      }
    }
  }
}
