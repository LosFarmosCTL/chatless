import Auth
import Chat
import SwiftData
import SwiftUI
import Twitch
import TwitchSession

struct RootView: View {
  @EnvironmentObject private var auth: AuthenticationStore
  @EnvironmentObject private var sessionStore: TwitchSessionStore
  @EnvironmentObject private var channelRegistry: ChannelEventStateRegistry
  @EnvironmentObject private var globalEventState: GlobalEventState

  @Query private var channels: [ChatChannel]
  @State private var trackedChannelIDs: Set<String> = []

  var body: some View {
    ContentView()
      .task {
        for await activeUserID in auth.$activeUserID.values {
          await handleAuthChange(activeUserID)
        }
      }
      .task(id: channels.map(\.channelID)) {
        updateChannels(with: Set(channels.map(\.channelID)))
      }
  }

  @MainActor
  private func handleAuthChange(_ activeUserID: String?) async {
    guard
      let activeUserID,
      let tokens = auth.activeTokens,
      auth.tokenValidForActiveUser(),
      let profile = auth.activeProfile
    else {
      await clearSession()
      return
    }

    await sessionStore.switchAccount(
      to: .init(
        oAuth: tokens.accessToken,
        clientID: tokens.clientID,
        userID: activeUserID,
        userLogin: profile.login
      ))

    channelRegistry.apply(session: sessionStore.session)
    if let session = sessionStore.session {
      globalEventState.start(session: session)
    } else {
      globalEventState.stop()
    }
  }

  @MainActor
  private func updateChannels(with channelIDs: Set<String>) {
    let added = channelIDs.subtracting(trackedChannelIDs)
    let removed = trackedChannelIDs.subtracting(channelIDs)

    for channelID in added { channelRegistry.getOrCreateChannel(channelID) }
    for channelID in removed { channelRegistry.removeChannel(channelID) }

    trackedChannelIDs = channelIDs
  }

  @MainActor
  private func clearSession() async {
    await sessionStore.logout()

    channelRegistry.apply(session: nil)
    globalEventState.stop()
  }
}
