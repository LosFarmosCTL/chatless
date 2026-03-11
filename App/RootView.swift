import Auth
import Chat
import SwiftData
import SwiftUI
import Twitch
import TwitchSession

struct RootView: View {
  @Environment(AuthenticationStore.self) private var auth
  @Environment(TwitchSessionStore.self) private var sessionStore
  @Environment(GlobalEventState.self) private var globalEventState
  @Environment(\.channelEventRegistry) private var channelRegistry: ChannelEventStateRegistry!

  @Query private var channels: [ChatChannel]
  @State private var trackedChannelIDs: Set<String> = []

  var body: some View {
    ContentView()
      .task(id: auth.activeUserID) {
        await handleAuthChange(auth.activeUserID)
      }
      .task(id: channels.map(\.channelID)) {
        channelRegistry.syncChannels(to: Set(channels.map(\.channelID)))
      }
  }

  @MainActor
  private func handleAuthChange(_ activeUserID: String?) async {
    guard
      let activeUserID,
      let tokens = auth.activeToken,
      let profile = auth.activeProfile,
      !tokens.isExpired()
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
  private func clearSession() async {
    await sessionStore.logout()

    channelRegistry.apply(session: nil)
    globalEventState.stop()
  }
}
