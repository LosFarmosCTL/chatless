import Auth
import Chat
import SwiftData
import SwiftUI
import TwitchSession

@main
struct ChatlessApp: App {
  private let container: ModelContainer
  @StateObject private var auth: AuthenticationStore
  @StateObject private var sessionStore: TwitchSessionStore
  @StateObject private var channelRegistry: ChannelEventStateRegistry
  @StateObject private var globalEventState: GlobalEventState

  init() {
    // swiftlint:disable:next force_try
    let localContainer = try! ModelContainer(for: AuthenticatedUser.self, ChatChannel.self)

    let localAuth = AuthenticationStore(
      modelContext: localContainer.mainContext
    )

    self.container = localContainer
    self._auth = StateObject(wrappedValue: localAuth)
    self._sessionStore = StateObject(wrappedValue: TwitchSessionStore())
    self._channelRegistry = StateObject(wrappedValue: ChannelEventStateRegistry())
    self._globalEventState = StateObject(wrappedValue: GlobalEventState())
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(auth)
        .environmentObject(sessionStore)
        .environmentObject(channelRegistry)
        .environmentObject(globalEventState)
        .modelContainer(container)
    }
  }
}
