import Account
import Auth
import Chat
import SwiftData
import SwiftUI
import TwitchSession

@main
struct ChatlessApp: App {
  private let container: ModelContainer

  @State private var auth: AuthenticationStore
  @State private var loginService: LoginService
  @State private var twitchClientStore: TwitchClientStore
  @State private var twitchAPIService: TwitchAPIService

  @State private var channelEventRegistry: ChannelEventStateRegistry
  @State private var globalEventState: GlobalEventState

  init() {
    // swiftlint:disable:next force_try
    self.container = try! ModelContainer(for: AuthenticatedUser.self, ChatChannel.self)

    let auth = AuthenticationStore(modelContext: container.mainContext)
    let loginService = LoginService(auth: auth)

    let twitchClientStore = TwitchClientStore()
    let twitchAPIService = TwitchAPIService(twitchClientStore: twitchClientStore)
    let channelEventRegistry = ChannelEventStateRegistry()
    let globalEventState = GlobalEventState()

    self._auth = State(initialValue: auth)
    self._loginService = State(initialValue: loginService)
    self._twitchClientStore = State(initialValue: twitchClientStore)
    self._twitchAPIService = State(initialValue: twitchAPIService)
    self._channelEventRegistry = State(initialValue: channelEventRegistry)
    self._globalEventState = State(initialValue: globalEventState)
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .modelContainer(container)

        .environment(auth)
        .environment(loginService)

        .environment(twitchClientStore)
        .environment(twitchAPIService)
        .environment(globalEventState)
        .environment(channelEventRegistry)
    }
  }
}
