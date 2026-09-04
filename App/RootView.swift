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
  @Environment(ChannelStore.self) private var channelStore

  @Environment(\.modelContext) private var modelContext
  @Query private var channels: [AddedChannel]

  @State private var isRefreshing: Bool = false

  private var channelLogins: [String: String] {
    Dictionary(channels.map { ($0.id, $0.login) }, uniquingKeysWith: { first, _ in first })
  }

  var body: some View {
    ContentView(isRefreshing: isRefreshing)
      .task(id: auth.activeAccount) { await handleAuthChange(auth.activeAccount) }
      .task(id: channelLogins) { channelStore.syncChannels(to: channelLogins) }
      .task(every: .seconds(60), isBusy: $isRefreshing) { await refreshChannels() }
  }

  @MainActor
  private func handleAuthChange(_ activeAccount: ActiveAccount?) async {
    guard !Task.isCancelled, auth.activeAccount == activeAccount else {
      return
    }

    channelStore.apply(context: nil)
    globalEventState.stop()

    guard let activeAccount else {
      await clearSession()
      return
    }

    await twitchClientStore.activate(account: activeAccount)

    guard !Task.isCancelled, auth.activeAccount == activeAccount else { return }

    channelStore.apply(context: twitchClientStore.context)

    if let context = twitchClientStore.context {
      globalEventState.start(context: context)
    } else {
      globalEventState.stop()
    }
  }

  @MainActor
  private func clearSession() async {
    await twitchClientStore.deactivate()

    guard !Task.isCancelled, auth.activeAccount == nil else { return }

    channelStore.apply(context: nil)
    globalEventState.stop()
  }

  private func refreshChannels() async {
    async let streamRefresh: Void = channelStore.refreshStreamStatus()

    await refreshChannelProfiles()
    await streamRefresh
  }

  private func refreshChannelProfiles() async {
    guard let contextID = twitchClientStore.context?.id else { return }

    let updater = AddedChannel.Updater(modelContainer: modelContext.container)

    for channelBatch in channels.chunked(into: 100) {
      guard !Task.isCancelled, twitchClientStore.context?.id == contextID else { return }

      if let users = try? await twitchAPI.request(.getUsers(ids: channelBatch.map(\.id))) {
        guard !Task.isCancelled, twitchClientStore.context?.id == contextID else { return }

        await updater.updateChannels(with: users)
      }
    }
  }
}
