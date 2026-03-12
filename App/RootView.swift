import Auth
import Chat
import SwiftData
import SwiftUI
import Twitch
import TwitchSession

struct RootView: View {
  @Environment(AuthenticationStore.self) private var auth
  @Environment(TwitchClientStore.self) private var twitchClientStore

  @Environment(GlobalEventState.self) private var globalEventState
  @Environment(ChannelEventStateRegistry.self) private var channelRegistry

  @Query private var channels: [ChatChannel]

  var body: some View {
    ContentView()
      .task(id: auth.activeAccount) { await handleAuthChange(auth.activeAccount) }
      .task(id: channels) { channelRegistry.syncChannels(to: Set(channels.map(\.channelID))) }
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
}
